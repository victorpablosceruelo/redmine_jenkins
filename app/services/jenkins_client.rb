require 'jenkins_api_client'

class JenkinsClient

  def initialize(url, opts = {}, logger = nil)
    @url = url

    @options = {}
    @options[:server_url] = @url
    @options[:http_open_timeout] = opts[:http_open_timeout] || 5
    @options[:http_read_timeout] = opts[:http_read_timeout] || 60
    @options[:username] = opts[:username] if opts.has_key?(:username)
    @options[:password] = opts[:password] if opts.has_key?(:password)
    
    if (nil == logger)
	@log_location = STDOUT unless @log_location
	@log_level = Logger::INFO unless @log_level
	@logger = Logger.new(@log_location)
	@logger.level = @log_level
    else 
	@logger = logger
    end

  end


  def connection
    client = JenkinsApi::Client.new(@options)
    client.logger = @logger
    return client
  rescue ArgumentError => e
	errorMsg = "Connection error: " + e.message
	@logger.error errorMsg
	@logger.error e.backtrace.join("\n")
	raise RedmineJenkins::Error::JenkinsConnectionError, e
  rescue Unauthorized => e
	errorMsg = "Connection error: " + e.message
	@logger.error errorMsg
	@logger.error e.backtrace.join("\n")
	raise RedmineJenkins::Error::JenkinsConnectionError, e
  rescue => e
	errorMsg = "Connection error: " + e.message
        @logger.error errorMsg
	@logger.error e.backtrace.join("\n")
	raise e
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
	get_jobs_list_filtered([])
  end

  def get_jobs_list_filtered(filter)
	response_json_jobs = connection.job.list_all_with_details rescue []
	jobs = get_jobs_list_aux(response_json_jobs, '', filter, [])
	# connection.job.list_all rescue []
	jobs
  end

  def number_of_builds_for(job_name)
    job_suburl = name2url(job_name)
    connection.job.list_details(job_suburl)['builds'].size rescue 0
  end

  private

  def get_jobs_list_aux(response_jobs_json, prefix, filter, jobs_accumulator)
	# @logger.info "Filter #{filter}"
	filtered_out_jobs = ''
	response_jobs_json.each do |job|
           job_name = job["name"]
           new_prefix = compute_new_prefix(prefix, job_name)

	   # @logger.info "get_jobs_list_aux: new_prefix: #{new_prefix} "
           # @logger.debug "get_jobs_list: If isFolder('#{job["name"]}') -> getSubfolders "
           # @logger.debug "JSON: '#{job}'"


           if (! job_path_is_filtered_out(new_prefix, filter))
              if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
                 job_suburl = name2url(new_prefix)
                 # @logger.debug "Job is a folder. Getting details of folder '#{new_prefix}' ('#{job_suburl}'): "
                 details_response_json = connection.job.list_details(job_suburl)
                 # @logger.debug "Response JSON: '#{details_response_json}'"

                 jobs_accumulator = get_jobs_list_aux(details_response_json["jobs"], new_prefix, filter, jobs_accumulator) rescue jobs_accumulator
              else
                 jobs_accumulator << new_prefix
              end

           else
		filtered_out_jobs << "Job: #{job_name} [ #{new_prefix} ]; "
		# @logger.info "Job path has been filtered: #{new_prefix} Filter: #{filter}"
           end
        end
	@logger.info "Filter #{filter}"
	@logger.info "Filtered out jobs: #{filtered_out_jobs} "
	@logger.info "Valid jobs found: #{jobs_accumulator} "
        return jobs_accumulator
  end

  def job_path_is_filtered_out(new_prefix, filter)
	prefix_lower_case = new_prefix.downcase

	filter.each do |subfilter|
		if (subfilter.length > prefix_lower_case.length)
			if (subfilter.start_with?(prefix_lower_case))
				return false
			end
		else
			if (prefix_lower_case.start_with?(subfilter))
				return false
			end
		end
	end

	return true
  end

  def name2url(job_name)
    job_name.gsub('/', '/job/')
  end

  def compute_new_prefix(prefix, job_or_folder_name)
    if '' == prefix
      new_prefix = job_or_folder_name
    else
      new_prefix = prefix + '/' + job_or_folder_name
    end
    new_prefix
  end

end
