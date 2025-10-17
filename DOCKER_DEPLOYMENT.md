# Docker Deployment Considerations

## Current Implementation Analysis

### File Upload/Import Issues

**Current Behavior:**
- Files are saved to `Rails.root/tmp/imports/` directory
- Background job reads from this path
- File is deleted after processing

**Docker Concerns:**

1. **Ephemeral Storage**: Container filesystems are temporary
   - Files in `/tmp` are lost on container restart
   - Not shared between multiple container instances (horizontal scaling)

2. **Background Jobs**: If using separate worker containers
   - Web container saves file to its local `/tmp`
   - Worker container can't access web container's filesystem
   - Job will fail with "file not found"

### CSV Export
✅ **No Issues** - Client-side export via AG Grid, doesn't touch server storage

---

## Recommended Solutions

### Option 1: Active Storage with S3/Cloud Storage (Recommended for Production)

**Best for:** Production deployments, multi-container setups, horizontal scaling

```ruby
# Gemfile
gem "aws-sdk-s3", require: false

# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: <%= ENV['AWS_REGION'] %>
  bucket: <%= ENV['AWS_S3_BUCKET'] %>

# config/environments/production.rb
config.active_storage.service = :amazon
```

**Changes needed:**

```ruby
# app/controllers/imports_controller.rb
def create
  uploaded_file = params[:file]
  
  import_batch = ImportBatch.create!(
    filename: uploaded_file.original_filename,
    status: 'pending'
  )
  
  # Use Active Storage
  import_batch.file.attach(uploaded_file)
  
  GrantImportJob.perform_later(import_batch.id)
  
  redirect_to import_batch_path(import_batch), 
    notice: 'File uploaded successfully. Import is being processed.'
end

# app/jobs/grant_import_job.rb
def perform(import_batch_id)
  import_batch = ImportBatch.find(import_batch_id)
  
  # Download from S3 to temp location
  temp_file = Tempfile.new(['import', '.xlsx'])
  begin
    import_batch.file.download { |chunk| temp_file.write(chunk) }
    temp_file.rewind
    
    service = GrantImportService.new(temp_file.path, import_batch)
    service.import
  ensure
    temp_file.close
    temp_file.unlink
  end
end

# Add to ImportBatch model
class ImportBatch < ApplicationRecord
  has_one_attached :file
  # ... rest of model
end
```

### Option 2: Shared Volume (Simpler for Single-Node)

**Best for:** Single-server deployments, Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    volumes:
      - import_storage:/app/tmp/imports
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:password@db/grant_importer_production
      REDIS_URL: redis://redis:6379/0

  worker:
    build: .
    command: bundle exec sidekiq
    volumes:
      - import_storage:/app/tmp/imports  # Same volume as web
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:password@db/grant_importer_production
      REDIS_URL: redis://redis:6379/0

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: password

  redis:
    image: redis:7-alpine

volumes:
  import_storage:  # Shared between web and worker
  postgres_data:
```

**Pros:**
- Minimal code changes
- Simple setup
- Works with current implementation

**Cons:**
- Only works on single Docker host
- Doesn't scale horizontally across multiple servers
- Volume management needed

### Option 3: Process Synchronously (No Background Job)

**Best for:** Low-volume imports, simple deployments

```ruby
# app/controllers/imports_controller.rb
def create
  uploaded_file = params[:file]
  
  import_batch = ImportBatch.create!(
    filename: uploaded_file.original_filename,
    status: 'processing'
  )
  
  # Process immediately instead of background job
  temp_file = Tempfile.new(['import', '.xlsx'])
  begin
    temp_file.write(uploaded_file.read)
    temp_file.rewind
    
    service = GrantImportService.new(temp_file.path, import_batch)
    service.import
  ensure
    temp_file.close
    temp_file.unlink
  end
  
  redirect_to import_batch_path(import_batch), 
    notice: 'Import completed successfully.'
end
```

**Pros:**
- No storage issues
- No background job complexity
- Simple Docker setup

**Cons:**
- Blocks HTTP request (slow for large files)
- User waits for entire import
- Can timeout on large imports

---

## Complete Docker Setup Example

### Dockerfile

```dockerfile
FROM ruby:3.3-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    tzdata

WORKDIR /app

# Copy Gemfile
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application
COPY . .

# Precompile assets (if needed)
RUN bundle exec rails assets:precompile

# Create tmp directory for imports
RUN mkdir -p tmp/imports

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - import_storage:/app/tmp/imports
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:password@db/grant_importer_production
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: production
      RAILS_LOG_TO_STDOUT: "true"
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}

  worker:
    build: .
    command: bundle exec sidekiq
    volumes:
      - import_storage:/app/tmp/imports
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:password@db/grant_importer_production
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: production
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: grant_importer_production
      POSTGRES_PASSWORD: password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  import_storage:
  postgres_data:
  redis_data:
```

### Configuration Changes Needed

```ruby
# config/environments/production.rb
Rails.application.configure do
  # ... existing config ...
  
  # Use Sidekiq for background jobs
  config.active_job.queue_adapter = :sidekiq
  
  # Ensure tmp directory exists
  config.after_initialize do
    FileUtils.mkdir_p(Rails.root.join('tmp', 'imports'))
  end
end

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
end
```

---

## Deployment Checklist

- [ ] Choose storage strategy (S3, Shared Volume, or Synchronous)
- [ ] Set up Redis for Sidekiq (if using background jobs)
- [ ] Configure DATABASE_URL for PostgreSQL
- [ ] Generate and set SECRET_KEY_BASE environment variable
- [ ] Set up persistent volumes for database and file storage
- [ ] Configure health checks for all services
- [ ] Set up log aggregation (Docker logs are ephemeral)
- [ ] Configure backup strategy for PostgreSQL
- [ ] Set resource limits (memory, CPU) for containers
- [ ] Enable HTTPS/SSL termination (via reverse proxy like nginx)
- [ ] Set up monitoring (e.g., Docker stats, Prometheus)

---

## Quick Start Commands

```bash
# Generate secret key
docker run --rm ruby:3.3 ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"

# Build and start services
docker-compose build
docker-compose up -d

# Create database
docker-compose exec web rails db:create db:migrate

# View logs
docker-compose logs -f web worker

# Stop services
docker-compose down
```

---

## Scaling Considerations

### Horizontal Scaling (Multiple Web/Worker Containers)

**Required:**
- Use S3/cloud storage (not shared volumes)
- Load balancer in front of web containers
- Multiple worker containers for faster processing

```yaml
# docker-compose scale example
docker-compose up -d --scale web=3 --scale worker=2
```

### Performance Tuning

```ruby
# config/puma.rb (in production)
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Sidekiq concurrency
# docker-compose.yml
worker:
  command: bundle exec sidekiq -c 10  # 10 concurrent jobs
```

---

## Cost Considerations

| Option | Infrastructure Cost | Development Effort | Scalability |
|--------|---------------------|-------------------|-------------|
| S3/Cloud Storage | $$$ (pay per GB/request) | High | Excellent |
| Shared Volume | $ (storage only) | Low | Limited |
| Synchronous | $ (no extra services) | Low | Poor |

**Recommendation:** Start with Shared Volume (Option 2) for MVP, migrate to S3 (Option 1) when scaling.
