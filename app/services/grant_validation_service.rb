class GrantValidationService
  def initialize(grant)
    @grant = grant
    @warnings = []
  end
  
  def validate_with_warnings
    check_duplicate_grants
    check_amount_reasonableness
    check_date_consistency
    check_project_name_exists
    
    @warnings
  end
  
  private
  
  def check_duplicate_grants
    duplicate = Grant.where(
      funder_name: @grant.funder_name,
      fiscal_year: @grant.fiscal_year
    ).where.not(id: @grant.id).first
    
    if duplicate
      @warnings << "Possible duplicate: Similar grant exists for #{@grant.funder_name} in #{@grant.fiscal_year}"
    end
  end
  
  def check_amount_reasonableness
    if @grant.amount_requested && @grant.amount_requested > 10_000_000
      @warnings << "Amount requested (#{@grant.amount_requested}) is unusually high"
    end
    
    if @grant.amount_awarded && @grant.amount_requested && 
       @grant.amount_awarded > @grant.amount_requested
      @warnings << "Amount awarded exceeds amount requested"
    end
  end
  
  def check_date_consistency
    if @grant.deadline && @grant.submission_date && 
       @grant.submission_date > @grant.deadline
      @warnings << "Submission date is after deadline"
    end
  end
  
  def check_project_name_exists
    if @grant.project_name && @grant.project_name.length < 3
      @warnings << "Project name seems too short"
    end
  end
end
