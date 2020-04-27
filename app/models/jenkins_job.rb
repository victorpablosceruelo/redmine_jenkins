class JenkinsJob < ActiveRecord::Base
  unloadable

  ## Relations
  belongs_to :project
  belongs_to :repository
  has_many   :builds, class_name: 'JenkinsBuild', dependent: :destroy

  # Technical Debt (sqale_index)
  # Effort to fix all Code Smells. The measure is stored in minutes in the database. 
  # An 8-hour day is assumed when values are shown in days.
  attr_accessible :name, :repository_id, :builds_to_keep, :sonarqube_dashboard_url, :state_color,
                  # Quality Gate
                  :sources_alert_status,
                  # Size
                  :sources_lines,
                  # Reliability
                  :sources_reliability_rating, :sources_bugs,
                  # Security
                  :sources_security_rating, :sources_vulnerabilities,
                  # Maintainability
                  :sources_sqale_rating, :sources_sqale_debt_ratio, 
                  :sources_sqale_index, :sources_code_smells, 
                  # Issues
                  :sources_violations,
                  # Coverage
                  :sources_coverage, :sources_tests, :sources_skipped_tests,
                  # Complexity
                  :sources_complexity, :sources_duplicated_lines_density
                  

  ## Validations
  validates :project_id,     presence: true
  validates :repository_id,  presence: true
  validates :name,           presence: true, uniqueness: { scope: :project_id }
  validates :builds_to_keep, presence: true

  ## Serializations
  serialize :health_report, Array

  ## Delegators
  delegate :jenkins_connection, :wait_for_build_id, :jenkins_url, :jenkins_setting, to: :project


  def to_s
    name
  end


  def job_id
    name.underscore.gsub(' ', '_')
  end


  def url
    "#{jenkins_url}/job/" + name2url
  end

  def name2url
    name.gsub('/', '/job/')
  end

  def latest_build_url
    "#{url}/#{latest_build_number}"
  end


  def console
    console_output =
      begin
        jenkins_connection.job.get_console_output(name2url, latest_build_number)['output'].gsub('\r\n', '<br />')
      rescue => e

        errorMsg = "Jenkins Response: " + e.message
        logger.error errorMsg
        logger.error e.backtrace.join("\n")

        e.message

      end
    console_output
  end

end
