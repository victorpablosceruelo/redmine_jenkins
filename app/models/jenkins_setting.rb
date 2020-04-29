class JenkinsSetting < ActiveRecord::Base
  unloadable

  ## Relations
  belongs_to :project

  ## Validations
  validates :project_id, presence: true, uniqueness: true


  def jenkins_connection
    jenkins_client.connection
  end


  def test_connection
    jenkins_client.test_connection
  end


  def get_jobs_list
    jenkins_client.get_jobs_list
  end

  def get_jobs_list_filtered(filter)
    jenkins_client.get_jobs_list_filtered(filter)
  end

  def number_of_builds_for(job_name)
    jenkins_client.number_of_builds_for(job_name)
  end

  def auth_user
	  tmp = ENV["JENKINS_USER"]
	  if ! tmp.blank?
		  return tmp
	  end
	  return 'JenkinsUserName' 
  end

  def auth_password
	  tmp = ENV["JENKINS_TOKEN"]
          if ! tmp.blank?
                  return tmp
          end
	  return 'JenkinsUserPwd'
  end

  def url
	  tmp = ENV["JENKINS_URL"]
          if ! tmp.blank?
                  return tmp
          end
	  return 'http://not.configured.yet'
  end

  def sonarqube_auth_user
          tmp = ENV["SONARQUBE_USER"]
          if ! tmp.blank?
                  return tmp
          end
          return 'SonarQubeUserName'
  end

  def sonarqube_auth_password
          tmp = ENV["SONARQUBE_PWD"]
          if ! tmp.blank?
                  return tmp
          end
          return 'SonarQubeUserPwd'
  end


  def show_compact
	return false
  end

  def wait_for_build_id
	return false
  end

  private


    def jenkins_client
	    if nil == @jenkins_client
	    	logger.info "JenkinsSetting::jenkins_client::JenkinsClient.new(#{url}, #{jenkins_options}) "
	    end
	    
	    @jenkins_client ||= JenkinsClient.new(url, jenkins_options, logger)
    end


    def jenkins_options
      options = {}
      options[:username] = auth_user if !auth_user.empty?
      options[:password] = auth_password if !auth_password.empty?
      options
    end

end
