class JenkinsJobsController < ApplicationController
  unloadable

  # Redmine ApplicationController method
  before_action :find_project_by_project_id

  before_action :can_build_jenkins_jobs, only:   [:build]
  before_action :find_job,               except: [:index, :new, :create]

  layout Proc.new { |controller| controller.request.xhr? ? false : 'base' }

  helper :redmine_bootstrap_kit
  helper :jenkins

  def index
	redirect_to jenkins_path(@project)
  end

  def show
    render_404
  end


  def new
    @job  = @project.jenkins_jobs.new
    @jobs = available_jobs
  end


  def create
	  # logger.info "JenkinsJobsController::create"

	  # Security issues
	  if ! User.current.allowed_to?(:edit_jenkins_settings, @project)
		  logger.error "Could NOT create job."
		  flash[:notice] = l(:notice_job_add_failed)
		  # @jobs = available_jobs
		  render_js_redirect
		  return
	  end

    @job = @project.jenkins_jobs.new(params[:jenkins_jobs])
    if @job.save
      flash[:notice] = l(:notice_job_added)
      result = BuildManager.create_builds!(@job, logger)
      flash[:error] = result.message_on_errors if !result.success?
      render_js_redirect
    else
	    logger.error "Could NOT create job."
	    @jobs = available_jobs
    end
  end


  def edit
    @jobs = jobs_list_filtered
  end


  def update
	  logger.info "JenkinsJobsController::update"

	  # Security issues
          if ! User.current.allowed_to?(:edit_jenkins_settings, @project)
                  logger.error "Could NOT update job."
                  flash[:notice] = l(:notice_job_update_failed)
                  # @jobs = available_jobs
                  render_js_redirect
                  return
          end

    if @job.update_attributes(params[:jenkins_jobs])
      flash[:notice] = l(:notice_job_updated)
      result = BuildManager.update_all_builds!(@job, logger)
      flash[:error] = result.message_on_errors if !result.success?
      render_js_redirect
    else
	    logger.error "Could NOT update job."
	    @jobs = available_jobs
    end
  end


  def destroy
	if User.current.allowed_to?(:edit_jenkins_settings, @project)
    		flash[:notice] = l(:notice_job_deleted) if @job.destroy
	else
		flash[:notice] = l(:notice_job_delete_failed)
	end
    render_js_redirect
  end


  def build
    result = BuildManager.trigger_build!(@job, logger)
    if result.success?
      flash.now[:notice] = result.message_on_success
    else
      flash.now[:error] = result.message_on_errors
    end
  end


  def history
    @builds = @job.builds.ordered.paginate(page: params[:page], per_page: 5)
  end


  def console
    @console_output = @job.console
  end


  def refresh
    result = BuildManager.update_last_build!(@job, logger)
    flash.now[:error] = result.message_on_errors if !result.success?
  end


  private


    def can_build_jenkins_jobs
      render_403 unless User.current.allowed_to?(:build_jenkins_jobs, @project)
    end


    def find_job
      @job = @project.jenkins_jobs.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_404
    end


    def success_url
      settings_project_path(@project, 'jenkins')
    end


    def render_js_redirect
	logger.info "JenkinsJobsController::render_js_redirect"
	logger.info "window.location = #{success_url.to_json};"
	# logger.info "respond_to: #{respond_to} "

	# respond_to do |format|
		# logger.info "format: #{format} "
		# format.html {redirect_to success_url}
		# format.js { render js: "window.location = #{success_url.to_json};" }
		# format.html { render :new, :locals => { :career => @career} }
	# end
	
	redirect_to success_url
    end


    def available_jobs
      jobs_list_filtered - @project.jenkins_jobs.map(&:name)
    end

    def jobs_list_filtered

	    # logger.warn "instance_methods: #{Repository::Git.instance_methods(true)} "

	    invalid_subpath = ENV["GITLAB_REPOS_BASE_PATH"]
	    if invalid_subpath.blank?
		    invalid_subpath = "/"
	    end

	    paths_filter = []
	    @project.repositories.each do |repo| 
		    # logger.warn "identifier: #{repo.identifier} "
		    # logger.warn "id: #{repo.id} "
		    # logger.warn "url: #{repo.url} "
		    # logger.warn "singleton_methods: #{repo.singleton_methods} "
		    # logger.warn "repo.root_url: #{repo.root_url} "
		    # logger.warn "repo: #{repo.to_s} "
		    valid_path = getReposValidPath(repo.root_url, invalid_subpath)
		    paths_filter.push valid_path
	    end

	    @project.jenkins_setting.get_jobs_list_filtered(paths_filter)
    end

    private

    def getReposValidPath(original_path, invalid_subpath)

	    # if invalid_subpath.include?(invalid_subpath)
	    if original_path.start_with?(invalid_subpath)
		  path = original_path[invalid_subpath.length, original_path.length]
	    else
		  path = original_path 
	    end

	    logger.warn "getReposValidPath(#{original_path},#{invalid_subpath}) => #{path} "
	    return path
    end

end
