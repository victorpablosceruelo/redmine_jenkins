require 'jenkins_api_client'
require 'logger'

class JenkinsClient

  def initialize(url, opts = {})
    @url = url

    @options = {}
    @options[:server_url] = @url
    @options[:http_open_timeout] = opts[:http_open_timeout] || 5
    @options[:http_read_timeout] = opts[:http_read_timeout] || 60
    @options[:username] = opts[:username] if opts.has_key?(:username)
    @options[:password] = opts[:password] if opts.has_key?(:password)

    @log_location = STDOUT unless @log_location
    @log_level = Logger::INFO unless @log_level
    @logger = Logger.new(@log_location)
    @logger.level = @log_level

  end


  def connection
    JenkinsApi::Client.new(@options)
  rescue ArgumentError => e
    raise RedmineJenkins::Error::JenkinsConnectionError, e
  end


  def test_connection
    test = {}
    test[:errors] = []

    begin
      test[:jobs_count] = connection.job.list_all.size
    rescue => e
      test[:jobs_count] = 0
      test[:errors] << e.message
    end

    begin
      test[:version] = connection.get_jenkins_version
    rescue => e
      test[:version] = 0
      test[:errors] << e.message
    end

    return test
  end


  def get_jobs_list
    response_json_jobs = connection.job.list_all_with_details rescue []
    jobs = []
    response_json_jobs.each do |job|
      @logger.info "Details for job '#{job["name"]}':"
      @logger.info "'#{job}'"
      if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
        details_response_json = connection.job.list_details job["name"]
        @logger.info "Job is a folder. Details: "
        @logger.info "'#{details_response_json}'"
      end
      jobs << job["name"] 
    end
    # connection.job.list_all rescue []
    jobs
  end


  def number_of_builds_for(job_name)
    connection.job.list_details(job_name)['builds'].size rescue 0
  end

end
