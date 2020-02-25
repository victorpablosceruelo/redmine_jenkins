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
  rescue Unauthorized => e
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
    jobs = get_jobs_list_aux(response_json_jobs, '', [])
    # connection.job.list_all rescue []
    jobs
  end

  def get_jobs_list_aux(response_jobs_json, prefix, jobs_accumulator)
    response_jobs_json.each do |job|
      job_name = job["name"]
      new_prefix = compute_new_prefix(prefix, job_name)

      @logger.info "get_jobs_list: If isFolder('#{job["name"]}') -> getSubfolders "
      @logger.info "'#{job}'"


      if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
        job_suburl = name2url(new_prefix)
        @logger.info "Job is a folder. Getting details of folder '#{new_prefix}' ('#{job_suburl}'): "
        details_response_json = connection.job.list_details(job_suburl)
        @logger.info "'#{details_response_json}'"
        
        jobs_accumulator = get_jobs_list_aux(details_response_json["jobs"], new_prefix, jobs_accumulator) rescue jobs_accumulator
      else
        jobs_accumulator << compute_new_prefix(prefix, job_name)
      end
    end
    jobs_accumulator
  end

  def compute_new_prefix(prefix, job_name)
    if '' == prefix
      new_prefix = job_name
    else
      new_prefix = prefix + '/' + job_name
    end
    new_prefix
  end

  def name2url(job_name)
    job_name.gsub('/', '/job/')
  end

  def number_of_builds_for(job_name)
    job_suburl = name2url(job_name)
    connection.job.list_details(job_suburl)['builds'].size rescue 0
  end

end
