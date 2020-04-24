class JenkinsBuildPresenter < SimpleDelegator

  attr_reader :jenkins_job_build

  def initialize(jenkins_job_build, template)
    super(template)
    @jenkins_job_build = jenkins_job_build
  end


  def number
    jenkins_job_build.number
  end

  def finished_at
    convert_date_to_str(jenkins_job_build.finished_at)
  end

  def convert_date_to_str(date_value)
    if (date_value == nil)
      return "never"
    end
    date_value.strftime('%Y/%m/%d %H:%M')
  end

  def get_int_value(value_in)
    if ((value_in == nil) || (value_in == ''))
      return '0' 
    else 
      if (value_in.is_a? String)
        if (value_in.strip == '')
          return '0'
        end
      else
        return value_in.to_s
      end
    end
  end

  def minutes_to_hours(value_in)
    if ((value_in == nil) || (value_in == ''))
      return '0' 
    else 
      if (value_in.is_a? String)
        if (value_in.strip == '')
          return '0'
        end
      else
        return (value_in / 60).to_s
      end
    end
  end

  def alert_status_to_str(alert_status)
    if ((alert_status == nil) || (alert_status == ''))
      return l(:label_sources_report_cell_no_data)
    end

    return alert_status
  end

  private

    def render_latest_build_infos
      s = ''
      s << content_tag(:li, render_jenkins_job_latest_build_link_and_state(jenkins_job))

      s << content_tag(:li, latest_build_duration) 
      s << content_tag(:li, latest_build_date) 

      # s << content_tag(:li, link_to_console_output)
      s << content_tag(:li, '', class: 'icon icon-running') if jenkins_job.state == 'running'

      s.html_safe
    end


    def render_jenkins_job_latest_build_link_and_state(jenkins_job)
      img_desc = get_job_latest_build_image_description(jenkins_job)

      s = ''
      s << content_tag(:span, link_to_jenkins_job_latest_build(jenkins_job).html_safe, class: 'label label-info')
      s << content_tag(:span, state_color_to_image(jenkins_job.state_color, img_desc), class: 'job_status_line')
      # s << content_tag(:span, link_to_jenkins_job_latest_build_console(jenkins_job).html_safe, class: 'job_status_line')
      s << content_tag(:span, link_to_latest_build_console_output.html_safe, class: 'job_status_line')

      s.html_safe
    end

    def get_job_latest_build_image_description(jenkins_job)
	s = ''
	if (! jenkins_job.state.blank?)
		s << l(:label_job_build_state)
		s << ": "
		s << jenkins_job_state_to_label(jenkins_job.state)
		if (! jenkins_job.state_color.nil?) and (! jenkins_job.state_color.empty?)
       			s << " (" 
			s << jenkins_job.state_color
	 		s << ")"
		end
	end
	s.html_safe
    end 

    def latest_build_duration
	s = ''
	if !jenkins_job.latest_build_duration.nil?
		s << l(:label_job_duration)
		s << ': '
		s << Time.at(jenkins_job.latest_build_duration/1000).strftime("%M:%S") rescue "00:00"
	end
	s.html_safe
    end

    def getLiStyleForIcons
      "line-height:34px; margin:2px; vertical-align:middle; "
    end

    def latest_build_date
	s = ''
	if ! jenkins_job.latest_build_date.nil?
		s << l(:label_finished_at) 
		s << ": " 
		s << "#{format_time(jenkins_job.latest_build_date)}"
	end
	s.html_safe
    end

    def link_to_jenkins_job_latest_build_console
        if ! jenkins_job.latest_build_number.nil?
                url    = jenkins_job.latest_build_number == 0 ? 'javascript:void(0);' : jenkins_job.latest_build_url + '/console'
                target = jenkins_job.latest_build_number == 0 ? '' : '_blank'
                return link_to jenkins_logs_icon, url, target: target
                # Attributes included in image: longdesc: longdesc, alt: longdesc, title: longdesc
        end
        ''
    end

    def link_to_latest_build_console_output
	link_title = l(:label_see_console_output)
	if ! jenkins_job.latest_build_number.nil?
		if jenkins_job.latest_build_number == 0
			url = 'javascript:void(0);'
			return link_to(link_title, url, title: link_title, class: 'modal-box-close-only')
		else
			url = console_jenkins_job_path(jenkins_job.project, jenkins_job)
			return link_to(link_title, url, title: link_title, class: 'modal-box-close-only')

			# return link_to(link_title, url, title: link_title, class: 'modal-box-close-only')
		end
	end 

	# title: l(:label_see_console_output), remote: true, target:'_blank'
	return ''
    end


    def link_to_build
      link_to(fa_icon('fa-gears'), build_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_build_now), remote: true)
    end


    def link_to_refresh
      link_to(fa_icon('fa-refresh'), refresh_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_refresh_builds), remote: true)
    end


    def render_job_builds_infos_table_row(build)
	s = ''
	url = console_jenkins_job_path(jenkins_job.project, jenkins_job, build)
	link_title = "##{build.number}"
	s << content_tag(:td, link_to(link_title, url, title: link_title, class: 'modal-box-close-only'))
	
	s.html_safe
    end

    def render_changesets_list(changesets)
      visible_changesets = changesets.take(5)
      invisible_changesets = changesets - visible_changesets
      render_visible_changesets(visible_changesets) + render_invisible_changesets(invisible_changesets)
    end


    def render_visible_changesets(changesets)
      render_changesets(changesets, visible: true)
    end


    def render_invisible_changesets(changesets)
      render_display_more + render_changesets(changesets, visible: false) if !changesets.empty?
    end


    def render_changesets(changesets, opts = {})
      visible = opts.delete(:visible){ true }
      css_class = visible ? 'changesets visible' : 'changesets invisible'
      id = visible ? "changesets-visible-#{jenkins_job.id}" : "changesets-invisible-#{jenkins_job.id}"

      s = ''
      changesets.each do |changeset|
        s << content_tag(:li, content_for_changeset(changeset).html_safe)
      end

      content_tag(:div, s.html_safe, class: css_class, id: id)
    end


    def render_display_more
      link_to l(:label_display_more), '#', onclick: "$('#changesets-invisible-#{jenkins_job.id}').toggle(); return false;"
    end


    def content_for_changeset(changeset)
      s = ''
      s << content_tag(:p, link_to("##{changeset.revision[0..10]}", changeset_url(changeset)), class: 'revision')
      s << textilizable(changeset, :comments)
      s
    end


    def changeset_url(changeset)
      if !jenkins_job.repository.nil?
        { controller: 'repositories', action: 'revision', id: jenkins_job.project, repository_id: jenkins_job.repository.identifier_param, rev: changeset.revision }
      else
        '#'
      end
    end

    def last_data_update_warning_msg()
      l(:last_data_update_warning_msg, date: convert_date_to_str(jenkins_job.sources_report_last_update))
    end
end
