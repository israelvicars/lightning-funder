class Grant < ApplicationRecord
  belongs_to :import_batch

  before_validation :set_default_grant_name

  # Status enum
  VALID_STATUSES = [
    "Awarded - Active",
    "Awarded - Closed",
    "Submitted",
    "Planned",
    "Researching",
    "Abandoned"
  ].freeze

  # Mandatory field validations
  validates :funder_name, presence: true, length: { maximum: 255 }
  validates :grant_name, length: { maximum: 255 }
  validate :grant_name_or_funder_name_present
  validates :status, presence: true, inclusion: {
    in: VALID_STATUSES,
    message: "%{value} is not a valid status"
  }
  validates :project_name, presence: true, length: { maximum: 255 }
  validates :fiscal_year, presence: true,
    numericality: {
      only_integer: true,
      greater_than: 2000,
      less_than_or_equal_to: -> { Date.current.year + 5 }
    }

  # Optional field validations
  validates :amount_requested, numericality: {
    greater_than_or_equal_to: 0,
    allow_nil: true
  }
  validates :amount_awarded, numericality: {
    greater_than_or_equal_to: 0,
    allow_nil: true
  }

  validates :portal_website, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    allow_blank: true,
    message: "must be a valid URL"
  }

  # Custom business rule validations
  validate :award_end_after_start
  validate :fiscal_year_matches_dates
  validate :awarded_amount_not_exceeding_requested

  private

  def set_default_grant_name
    if grant_name.blank? && funder_name.present?
      self.grant_name = "#{funder_name} Grant"
    end
  end

  def grant_name_or_funder_name_present
    if grant_name.blank? && funder_name.blank?
      errors.add(:base, "Either Funder Name or Grant Name must be present")
    end
  end

  def award_end_after_start
    return if award_start_date.blank? || award_end_date.blank?

    if award_end_date < award_start_date
      errors.add(:award_end_date, "must be after award start date")
    end
  end

  def fiscal_year_matches_dates
    return if fiscal_year.blank?

    [ deadline, submission_date, date_awarded_declined ].compact.each do |date|
      if date.year != fiscal_year && (date.year - fiscal_year).abs > 1
        errors.add(:base, "Date #{date} seems inconsistent with fiscal year #{fiscal_year}")
      end
    end
  end

  def awarded_amount_not_exceeding_requested
    return if amount_requested.blank? || amount_awarded.blank?

    if amount_awarded > amount_requested * 1.1
      errors.add(:amount_awarded, "should not significantly exceed requested amount")
    end
  end
end
