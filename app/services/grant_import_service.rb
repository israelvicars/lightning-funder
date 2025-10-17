class GrantImportService
  COLUMN_MAPPING = {
    'A' => :funder_name,
    'B' => :grant_name,
    'C' => :status,
    'D' => :project_name,
    'E' => :fiscal_year,
    'F' => :deadline,
    'G' => :submission_date,
    'H' => :date_awarded_declined,
    'I' => :award_start_date,
    'J' => :award_end_date,
    'K' => :amount_requested,
    'L' => :amount_awarded,
    'M' => :date_notified,
    'N' => :upcoming_tasks,
    'O' => :portal_website,
    'P' => :portal_username,
    'Q' => :portal_password,
    'R' => :funder_location,
    'S' => :funder_contact_info,
    'T' => :funder_type,
    'U' => :opportunity_notes,
    'V' => :funder_notes,
    'W' => :grant_owner
  }.freeze
  
  attr_reader :import_batch, :errors
  
  def initialize(file_path, import_batch)
    @file_path = file_path
    @import_batch = import_batch
    @errors = []
  end
  
  def import
    begin
      spreadsheet = Roo::Spreadsheet.open(@file_path)
      process_spreadsheet(spreadsheet)
    rescue => e
      @import_batch.update(
        status: 'failed',
        error_details: { message: e.message, backtrace: e.backtrace.first(5) }
      )
      raise e
    end
  end
  
  private
  
  def process_spreadsheet(spreadsheet)
    sheet = spreadsheet.sheet(0)
    total_rows = sheet.last_row - 3
    
    @import_batch.update(
      status: 'processing',
      total_rows: total_rows
    )
    
    (4..sheet.last_row).each do |row_number|
      next if row_empty?(sheet, row_number)
      process_row(sheet, row_number)
    end
    
    @import_batch.update(status: 'completed')
  end
  
  def process_row(sheet, row_number)
    grant_attributes = extract_grant_attributes(sheet, row_number)
    
    return if grant_attributes.empty? || !has_mandatory_fields?(grant_attributes)
    
    grant_attributes[:import_batch_id] = @import_batch.id
    grant_attributes[:row_number] = row_number
    
    grant = Grant.new(grant_attributes)
    
    if grant.save
      @import_batch.increment!(:successful_rows)
    else
      @import_batch.increment!(:failed_rows)
      store_error(row_number, grant.errors.full_messages)
    end
  rescue => e
    @import_batch.increment!(:failed_rows)
    store_error(row_number, [e.message])
  end
  
  def extract_grant_attributes(sheet, row_number)
    attributes = {}
    
    COLUMN_MAPPING.each do |excel_col, attr_name|
      col_index = column_letter_to_index(excel_col)
      value = sheet.cell(row_number, col_index)
      
      next if value.nil? || value.to_s.strip.empty?
      
      attributes[attr_name] = normalize_value(attr_name, value)
    end
    
    attributes
  end
  
  def normalize_value(attr_name, value)
    case attr_name
    when :fiscal_year
      value.to_i
    when :amount_requested, :amount_awarded
      value.to_s.gsub(/[,$]/, '').to_f
    when :deadline, :submission_date, :date_awarded_declined, 
         :award_start_date, :award_end_date, :date_notified
      parse_date(value)
    else
      value.to_s.strip
    end
  end
  
  def parse_date(value)
    return nil if value.nil? || value.to_s.strip.empty?
    
    case value
    when Date, DateTime, Time
      value.to_date
    when Numeric
      Date.new(1899, 12, 30) + value.to_i
    else
      Date.parse(value.to_s) rescue nil
    end
  end
  
  def column_letter_to_index(letter)
    letter.upcase.chars.reduce(0) do |result, char|
      result * 26 + (char.ord - 'A'.ord + 1)
    end
  end
  
  def row_empty?(sheet, row_number)
    COLUMN_MAPPING.keys.all? do |excel_col|
      col_index = column_letter_to_index(excel_col)
      value = sheet.cell(row_number, col_index)
      value.nil? || value.to_s.strip.empty?
    end
  end
  
  def has_mandatory_fields?(attributes)
    key_fields = [:funder_name, :grant_name]
    key_fields.any? { |field| attributes[field].present? }
  end
  
  def store_error(row_number, messages)
    current_errors = @import_batch.error_details || {}
    current_errors[row_number.to_s] = messages
    @import_batch.update(error_details: current_errors)
  end
end
