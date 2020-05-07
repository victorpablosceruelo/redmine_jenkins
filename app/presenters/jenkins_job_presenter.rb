class JenkinsJobPresenter < SimpleDelegator

  attr_reader :jenkins_job

  def initialize(jenkins_job, template)
    super(template)
    @jenkins_job = jenkins_job
  end


  def job_id
    jenkins_job.job_id
  end


  def job_name
    longdesc = l(:label_see_jenkins_job) + jenkins_job.name
    link_to_job = link_to(jenkins_job.name, jenkins_job.url, target: '_blank', alt: longdesc, longdesc: longdesc, title: longdesc)
  end

  def job_description
      s = ''
      if ! jenkins_job.project.jenkins_setting.show_compact
      	if (!jenkins_job.nil?) and (!jenkins_job.description.nil?)
        	s << jenkins_job.description
     	end
      end
      s
  end

  def job_last_data_update_warning_msg()
      l(:label_last_data_update_warning_msg, date: convert_date_to_str(jenkins_job.sources_report_last_update))
  end

  def job_last_build_status
      img_desc = get_job_latest_build_image_description(jenkins_job)

      s = ''
      s << content_tag(:span, state_color_to_image(jenkins_job.state_color, img_desc), class: 'job_status_line')
      s.html_safe
  end


  def job_stability
    s = content_tag(:ul, build_history_list, class: 'list-unstyled')
    s.html_safe
  end


  def job_actions
    s = content_tag(:ul, job_actions_list, class: 'list-unstyled', style: "line-height:34px")
    s.html_safe
  end
 
  def render_sonarqube_report
    if (!('' == jenkins_job.sonarqube_dashboard_url))
      s = ''
      s << content_tag(:table, render_sonarqube_report_details, class: 'source_code_quality_report')
#      s << content_tag(:span, last_data_update_warning_msg, class: 'last_data_update_warning_msg')
      s << content_tag(:span, render_sonarqube_link_to_dashboard_msg, class: 'link_to_sonarqube_dashboard_url')
      return s.html_safe
    else
      return content_tag(:span, l(:label_no_sonarqube_report_available))
    end
  end


  private

	def render_sonarqube_link_to_dashboard_msg
		link = link_to_sonarqube_dashboard_url(jenkins_job.sonarqube_dashboard_url)

		s = ''
		s << l(:label_see_more_sonarqube_analisis_details_at, link: link) 
		s.html_safe
	end

  def render_sonarqube_report_details
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << content_tag(:tr, render_sonarqube_report_details_row1, class: 'table_odd_row')
    s << content_tag(:tr, render_sonarqube_report_details_row2)
    s << content_tag(:tr, render_sonarqube_report_details_row3, class: 'table_odd_row')
    # s << content_tag(:tr, render_sonarqube_report_details_row4)
    # s << content_tag(:tr, render_sonarqube_report_details_row5)
    # s << content_tag(:tr, render_sonarqube_report_details_row6)
    return s.html_safe
  end

  #:sources_vulnerabilities, :sources_bugs, :sources_code_smells, :sources_sqale_index,
  #                :sources_coverage, :sources_duplicated_lines_density, :sources_violations,
  #                :sources_alert_status, :sources_lines, :sources_tests, :sources_skipped_tests,
  #                :sources_complexity
  def render_sonarqube_report_details_row1
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << content_tag(:td, l(:label_sources_quality_gate), class: 'table_odd_col')
    s << content_tag(:td, alert_status_to_str(jenkins_job.sources_alert_status), class: 'table_even_col')

    s << content_tag(:td, l(:label_sources_lines), class: 'table_odd_col')
    s << content_tag(:td, get_int_value(jenkins_job.sources_lines), class: 'table_even_col')

    s << content_tag(:td, l(:label_sources_jenkins_build_date), class: 'table_odd_col')
    s << content_tag(:td, last_analysis_date, class: 'table_even_col')
    return s.html_safe
  end

  def last_analysis_date
    convert_date_to_str(jenkins_job.latest_build_date)
  end

  def render_sonarqube_report_details_row2
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << content_tag(:td, l(:label_sources_reliability), class: 'table_odd_col')
    s << content_tag(:td, render_sonarqube_report_details_cell_reliability, class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_security_rating), class: 'table_odd_col')
    s << content_tag(:td, convert_float_to_str('security', jenkins_job.sources_security_rating), class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_maintainability), class: 'table_odd_col')
    s << content_tag(:td, convert_float_to_str('squale', jenkins_job.sources_sqale_rating), class: 'table_even_col')
    return s.html_safe
  end

  def render_sonarqube_report_details_cell_reliability
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << convert_float_to_str('reliability', jenkins_job.sources_reliability_rating)
    # s << '<BR>'.html_safe
    # s << ' ('
    # s << get_int_value(jenkins_job.sources_bugs)
    # s << ' ' 
    # s << l(:label_sources_bugs) 
    # s << ')'
    return s.html_safe
  end

  def render_sonarqube_report_details_row4
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << content_tag(:td, l(:label_sources_vulnerabilities), class: 'table_odd_col')
    s << content_tag(:td, get_int_value(jenkins_job.sources_vulnerabilities), class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_technical_debt), class: 'table_odd_col')
    s << content_tag(:td, render_sonarqube_report_details_cell_sqale, class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_code_smells), class: 'table_odd_col')
    s << content_tag(:td, get_int_value(jenkins_job.sources_code_smells), class: 'table_even_col')
    return s.html_safe
  end

  def render_sonarqube_report_details_cell_sqale
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << get_int_value(jenkins_job.sources_sqale_index)
    s << ' ' 
    s << l(:label_sources_technical_debt_minutes)
    s << '<BR>'.html_safe
    s << '('
    s << '&#126;'.html_safe
    s << minutes_to_hours(jenkins_job.sources_sqale_index)
    s << ' h)' 
    return s.html_safe
  end

  def render_sonarqube_report_details_row3
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << content_tag(:td, l(:label_sources_coverage), class: 'table_odd_col')
    s << content_tag(:td, get_int_value(jenkins_job.sources_coverage), class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_tests), class: 'table_odd_col')
    s << content_tag(:td, get_int_value(jenkins_job.sources_tests), class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_skipped_tests), class: 'table_odd_col')
    s << content_tag(:td, get_int_value(jenkins_job.sources_skipped_tests), class: 'table_even_col')
    return s.html_safe
  end

  def render_sonarqube_report_details_row5
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << content_tag(:td, l(:label_sources_complexity), class: 'table_odd_col')
    s << content_tag(:td, get_int_value(jenkins_job.sources_complexity), class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_duplications), class: 'table_odd_col')
    s << content_tag(:td, render_sonarqube_report_details_cell_duplicated_lines, class: 'table_even_col')
    s << content_tag(:td, l(:label_sources_issues), class: 'table_odd_col')
    s << content_tag(:td, render_sonarqube_report_details_cell_violations, class: 'table_even_col')
    return s.html_safe
  end

  def render_sonarqube_report_details_cell_duplicated_lines
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << get_int_value(jenkins_job.sources_duplicated_lines_density)
    s << ' '
    s << l(:label_sources_duplicated_lines_density)
    return s.html_safe
  end

  def render_sonarqube_report_details_cell_violations
    if (jenkins_job == nil)
      return ""
    end

    s = ''
    s << get_int_value(jenkins_job.sources_violations)
    s << ' '
    s << l(:label_sources_violations)
    return s.html_safe
  end

  def convert_date_to_str(date_value)
    if (date_value == nil)
      return "never"
    end
    date_value.strftime('%Y/%m/%d %H:%M')
  end

  def convert_float_to_str(index_name, index_value)
    if ((nil == index_name) || (nil == index_value))
      return l(:label_sources_report_cell_no_data)
    end
    case index_name
    when 'squale' # maintainability
      if (index_value <= 5)
        return symbol_A
      elsif ((index_value > 6) && (index_value < 10))
        return symbol_B
      elsif ((index_value > 11) && (index_value < 20))
        return symbol_C
      elsif ((index_value > 21) && (index_value < 50))
        return symbol_D
      else
        return symbol_E
      end
    when 'reliability'
      if (index_value == 1)
        return symbol_A
      elsif ((index_value > 1) && (index_value <= 2))
        return symbol_B
      elsif ((index_value > 2) && (index_value <= 3))
        return symbol_C
      elsif ((index_value > 3) && (index_value <= 4))
        return symbol_D
      else
        return symbol_E
      end
    when 'security'
      if (index_value > 0.8)
        return symbol_A
      elsif ((index_value > 0.7) && (index_value < 0.8))
        return symbol_B
      elsif ((index_value > 0.5) && (index_value < 0.7))
        return symbol_C
      elsif ((index_value > 0.3) && (index_value < 0.5))
        return symbol_D
      else
        return symbol_E
      end
    else
      return index_value.to_s
    end
  end

  def symbol_A
    content_tag(:span,'A',class: 'symbol_A').html_safe
  end

  def symbol_B
    content_tag(:span,'B',class: 'symbol_B').html_safe
  end

  def symbol_C
    content_tag(:span,'C',class: 'symbol_C').html_safe
  end

  def symbol_D
    content_tag(:span,'D',class: 'symbol_D').html_safe
  end

  def symbol_E
    content_tag(:span,'E',class: 'symbol_E').html_safe
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

  def latest_changesets
    changesets = jenkins_job.builds.last.changesets rescue []
    return '' if changesets.empty?
    content_tag(:ul, render_changesets_list(changesets), class: 'changesets_list list-unstyled')
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

    def job_actions_list
      s = ''
      s << content_tag(:li, link_to_refresh, style: getLiStyleForIcons)
      if User.current.allowed_to?(:build_jenkins_jobs, jenkins_job.project)
        s << content_tag(:li, link_to_build, style: getLiStyleForIcons)
      end
      s.html_safe
    end

    def getLiStyleForIcons
      "line-height:34px; margin:2px; vertical-align:middle; "
    end

    def build_history_list
      s = ''
      
      if jenkins_job.health_report.any?
        jenkins_job.health_report.each do |health_report|
          s << content_tag(:li, render_health_report_element(health_report), style: getLiStyleForIcons)
        end
      end
  
      # s << content_tag(:li, link_to_history, style: getLiStyleForIcons)
      # s << content_tag(:li, render_job_history, style: getLiStyleForIcons)
      s.html_safe
    end
  

    def render_health_report_element(health_report)
      "#{weather_icon(health_report['iconUrl'], health_report['description'])}".html_safe
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

    def link_to_build
      link_to(fa_icon('fa-gears'), build_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_build_now), remote: true)
    end


    def link_to_refresh
      link_to(fa_icon('fa-refresh'), refresh_jenkins_job_path(jenkins_job.project, jenkins_job), title: l(:label_refresh_builds), remote: true)
    end


    def link_to_history
      jenkins_history_url = history_jenkins_job_path(jenkins_job.project, jenkins_job)
      jenkins_history_title = l(:label_see_jenkins_jobs_history)
      # modal_box_css_class = 'fa fa-lg fa-history modal-box-close-only'
      modal_box_css_class = 'modal-box-close-only'

      # icon_image = content_tag(:span, url_title, class: "fa fa-lg fa-history").html_safe
      # icon_image = fa_icon 'fa-history', text: "Jenkins Jobs\' History" 
      # link_to(icon_image, jenkins_history_url, class: 'modal-box-close-only', title: url_title)
      # , data: { "toggle" => "tooltip", "original-title" => "History", "title" => "History"} 
      # class: 'modal-box-close-only', data: { "toggle" => "tooltip", "original-title" => "Logout", "placement" => "bottom" }
      # data: {toggle: "modal", target: "#modal"} 
      # :data => { "toggle" => "tooltip", "original-title" => "Logout"},
      link_to(jenkins_history_title, jenkins_history_url, class: modal_box_css_class, title: jenkins_history_title)
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

end
