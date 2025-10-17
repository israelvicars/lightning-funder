# Deployment Guide

## Required Environment Variables

Before deploying, you must set the following environment variables:

### SECRET_KEY_BASE (Required)

Generate a new secret key:

```bash
rails secret
```

This will output a long string like:
```
be6c0af833d40643fde31573024b913a27509e722cbb9218dcf51a124e6d0128be6f332932c13d255cea7ed260f3d078a9b71bf992bbb8a39e6f4e7714ba5dd2
```

Set this as an environment variable in your deployment platform.

### DATABASE_URL (Required)

PostgreSQL connection string:
```
postgres://username:password@host:port/database_name
```

### REDIS_URL (Optional - if using background jobs)

Redis connection string:
```
redis://host:port/0
```

---

## Platform-Specific Instructions

### Render

1. Create a new Web Service
2. Connect your GitHub repository
3. Set environment variables in the Render dashboard:
   - `SECRET_KEY_BASE`: [generated secret from above]
   - `DATABASE_URL`: [automatically set by Render PostgreSQL]
   - `RAILS_ENV`: `production`

4. Build Command:
   ```
   bundle install && rails assets:precompile && rails db:migrate
   ```
   
   Or with trace for debugging:
   ```
   bundle install && rails assets:precompile && rails db:migrate --trace
   ```

5. Start Command:
   ```
   bundle exec puma -C config/puma.rb
   ```

**Note**: Rails credentials are NOT required. The app uses environment variables for all secrets.

### Heroku

```bash
# Set environment variables
heroku config:set SECRET_KEY_BASE=$(rails secret)

# Deploy
git push heroku main

# Run migrations
heroku run rails db:migrate
```

### Railway

1. Create a new project from GitHub
2. Add PostgreSQL database
3. Set environment variables:
   - `SECRET_KEY_BASE`: [generated secret]
   - `NIXPACKS_BUILD_CMD`: `bundle install && rails assets:precompile`
   - `NIXPACKS_START_CMD`: `rails db:migrate && rails server -b 0.0.0.0 -p $PORT`

### Fly.io

```bash
# Initialize
fly launch

# Set secret
fly secrets set SECRET_KEY_BASE=$(rails secret)

# Deploy
fly deploy
```

### Docker / Docker Compose

See [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md) for complete Docker setup.

Example `.env` file:
```bash
SECRET_KEY_BASE=your_generated_secret_key_here
DATABASE_URL=postgres://postgres:password@db/grant_importer_production
REDIS_URL=redis://redis:6379/0
RAILS_ENV=production
```

---

## Deployment Checklist

- [ ] Generate and set `SECRET_KEY_BASE`
- [ ] Set `DATABASE_URL` to PostgreSQL connection
- [ ] Run database migrations: `rails db:migrate`
- [ ] Precompile assets: `rails assets:precompile` (if needed)
- [ ] Set `REDIS_URL` if using background jobs
- [ ] Configure production host settings in `config/environments/production.rb`
- [ ] Set up SSL/HTTPS termination
- [ ] Test file upload functionality
- [ ] Verify background job processing works
- [ ] Check logs for any errors

---

## Post-Deployment Verification

1. Visit your app URL
2. Upload a test grant template
3. Verify import completes successfully
4. Check the grants grid loads
5. Test CSV export
6. Visit `/admin` to verify admin panel works

---

## Troubleshooting

### "Missing secret_key_base" Error

**Solution**: Set the `SECRET_KEY_BASE` environment variable
```bash
rails secret  # Generate a new secret
```

### "ActiveSupport::MessageEncryptor::InvalidMessage" Error

**Cause**: Rails is trying to decrypt credentials but master key is missing

**Solution**: This app doesn't use Rails credentials - it uses environment variables instead. This error should not occur with the latest code. If it does:
- Ensure you have the latest code from GitHub
- Verify `config.require_master_key = false` is in production.rb
- Add `--trace` to your deployment commands for more details

### File Upload Not Working

**Cause**: Ephemeral filesystem in Docker/Heroku

**Solutions**:
1. Use Active Storage with S3 (recommended for production)
2. Use shared volumes (Docker only)
3. Process synchronously without temp files

See [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md) for detailed solutions.

### Background Jobs Not Running

**Cause**: Missing Redis or Sidekiq not started

**Solutions**:
- Ensure `REDIS_URL` is set
- Start Sidekiq worker: `bundle exec sidekiq`
- Or use inline job processing (development only)

### Database Connection Errors

**Solution**: Verify `DATABASE_URL` is correctly formatted:
```
postgres://username:password@host:port/database_name
```

### Assets Not Loading

**Solution**: Precompile assets before deployment:
```bash
RAILS_ENV=production rails assets:precompile
```

---

## Security Notes

- **Never commit** `SECRET_KEY_BASE` to version control
- Use environment variables for all secrets
- Enable HTTPS in production
- Regularly update dependencies: `bundle update`
- Monitor logs for suspicious activity

---

## Quick Deploy Commands

### First Deploy
```bash
# Generate secret
rails secret

# Set in your platform (example: Heroku)
heroku config:set SECRET_KEY_BASE=<your-secret>

# Deploy
git push heroku main
heroku run rails db:migrate
```

### Subsequent Deploys
```bash
git push heroku main
```

---

## Support

For deployment issues, check:
- Application logs in your platform dashboard
- Database connection status
- Environment variables are set correctly
- Rails version compatibility with your platform
