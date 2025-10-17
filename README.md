# Grant Importer MVP

A Ruby on Rails application that imports grant data from Excel spreadsheets and provides a web-based data grid for editing grant records.

## Features

- **Spreadsheet Import**: Upload Excel files (.xlsx, .xls) with grant data
- **Data Grid Editor**: Edit grant records using AG Grid with inline editing
- **Validation**: Business rules and data validation for grant records
- **Background Processing**: Async import processing using Active Job
- **Import Tracking**: Monitor import progress and view error details
- **Export**: Export grant data to CSV

## Technology Stack

- Ruby on Rails 8.0
- PostgreSQL
- Roo gem for spreadsheet import
- AG Grid Community for data grid
- Sidekiq for background jobs (optional)

## Setup Instructions

### Prerequisites

- Ruby 3.3+
- PostgreSQL
- Bundler

### Installation

1. Navigate to the project directory:
```bash
cd grant_importer
```

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:create
rails db:migrate
```

4. Start the Rails server:
```bash
rails server
```

5. Open your browser and navigate to:
```
http://localhost:3000
```

## Usage

### Importing Grants

1. Navigate to the home page (root URL)
2. Click "Choose File" and select your Excel grant template
3. Click "Upload and Import"
4. Monitor the import progress on the import batch details page
5. View any errors in the import results

### Grant Template Format

The Excel template should have the following columns (A-W):

**Mandatory Fields:**
- A: Funder Name (String)
- B: Funding Opportunity / Grant Name (String)
- C: Status (Enum: "Awarded - Active", "Awarded - Closed", "Submitted", "Planned", "Researching", "Abandoned")
- D: Instrumentl Project Name (String)
- E: Fiscal Year (Integer)

**Optional Fields:**
- F: Deadline (Date)
- G: Submission Date (Date)
- H: Date Awarded/Declined (Date)
- I: Award Start Date (Date)
- J: Award End Date (Date)
- K: Amount Requested (Decimal)
- L: Amount Awarded (Decimal)
- M: Date Notified (Date)
- N: Upcoming Tasks (Text)
- O: Portal Website (URL)
- P: Portal Username (String)
- Q: Portal Password (String)
- R: Funder Location (String)
- S: Funder Contact Info (Text)
- T: Funder Type (String)
- U: Opportunity Notes (Text)
- V: Funder Notes (Text)
- W: Grant Owner (String)

### Editing Grants

1. Click "View All Grants" from the home page
2. Click on any cell to edit its value
3. Use the dropdown for Status field
4. Click "Save Changes" to persist your edits
5. Click "Export CSV" to download the current data

### Business Rules

The application enforces the following validation rules:

- Mandatory fields must be filled
- Status must be one of the valid options
- Fiscal year must be between 2000 and 5 years in the future
- Award end date must be after award start date
- Amounts must be non-negative
- Portal website must be a valid URL format

## Project Structure

```
grant_importer/
├── app/
│   ├── controllers/
│   │   ├── grants_controller.rb
│   │   ├── imports_controller.rb
│   │   └── import_batches_controller.rb
│   ├── models/
│   │   ├── grant.rb
│   │   └── import_batch.rb
│   ├── services/
│   │   ├── grant_import_service.rb
│   │   └── grant_validation_service.rb
│   ├── jobs/
│   │   └── grant_import_job.rb
│   └── views/
│       ├── grants/
│       │   └── index.html.erb
│       ├── imports/
│       │   └── new.html.erb
│       └── import_batches/
│           └── show.html.erb
├── db/
│   ├── migrate/
│   │   ├── [timestamp]_create_import_batches.rb
│   │   └── [timestamp]_create_grants.rb
│   └── schema.rb
└── config/
    └── routes.rb
```

## Background Jobs

By default, imports run using Active Job with the default adapter (inline for development).

For production, configure Sidekiq:

1. Add Redis connection details to `config/cable.yml`
2. Start Sidekiq: `bundle exec sidekiq`
3. Configure Active Job to use Sidekiq in `config/application.rb`:
```ruby
config.active_job.queue_adapter = :sidekiq
```

## Development

### Running Tests

```bash
rails test
```

### Code Quality

```bash
bundle exec rubocop
```

## API Endpoints

- `GET /` - Import upload page
- `POST /imports` - Upload and process import file
- `GET /import_batches/:id` - View import batch details
- `GET /grants` - View all grants (HTML) or JSON
- `PATCH /grants/:id` - Update a single grant
- `POST /grants/bulk_update` - Update multiple grants

## Future Enhancements

- User authentication and authorization
- Audit trail for all grant changes
- Email notifications for import completion
- Advanced filtering and search in data grid
- Duplicate detection during import
- File validation before processing
- Export to multiple formats (PDF, Excel)

## License

Internal use only - Instrumentl

## Support

For questions or issues, contact the development team.
