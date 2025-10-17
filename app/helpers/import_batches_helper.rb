module ImportBatchesHelper
  def status_class(status)
    case status
    when "pending"
      "badge-pending"
    when "processing"
      "badge-processing"
    when "completed"
      "badge-completed"
    when "failed"
      "badge-failed"
    else
      "badge-secondary"
    end
  end
end
