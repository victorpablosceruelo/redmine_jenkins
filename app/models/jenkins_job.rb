class JenkinsJob < ActiveRecord::Base
  unloadable

  ## Relations
  belongs_to :project
  belongs_to :repository
  has_many   :builds, class_name: 'JenkinsBuild', dependent: :destroy

  attr_accessible :name, :repository_id, :builds_to_keep, :sonarqube_dashboard_url, :state_color

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

        @log_location = STDOUT unless @log_location
        @log_level = Logger::INFO unless @log_level
        unless @logger
          @logger = Logger.new(@log_location)
          @logger.level = @log_level
        end

        errorMsg = "Jenkins Response: " + e.message
        @logger.error errorMsg
        @logger.error e.backtrace.join("\n")

        e.message

      end
    console_output
  end

end
