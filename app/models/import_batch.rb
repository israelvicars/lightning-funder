class ImportBatch < ApplicationRecord
  has_many :grants, dependent: :destroy
  
  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }
  
  validates :filename, presence: true
  
  def progress_percentage
    return 0 if total_rows.nil? || total_rows.zero?
    ((successful_rows + failed_rows).to_f / total_rows * 100).round(2)
  end
end
