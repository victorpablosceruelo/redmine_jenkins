# coding: utf-8

require 'redmine'

require 'redmine_jenkins'

Redmine::Plugin.register :redmine_jenkins do
  name 'Redmine CI/CD plugin (Jenkins and SonarQube)'
  author 'From GFI for SGAD - OT'
  description 'This is a Redmine plugin to manage the CI/CD workflows'
  version '2.0.0'
  url 'https://gitlab-ic.scae.redsara.es/OFICINA_TECNICA/redmine_jenkins'
  author_url 'https://gitlab-ic.scae.redsara.es/OFICINA_TECNICA/redmine_jenkins'

  project_module :jenkins do
    permission :view_jenkins_jobs,     {:jenkins  => [:index]}
    permission :build_jenkins_jobs,    {:jenkins  => [:start_build]}
    permission :view_build_activity,   {:activity => [:index]}
    permission :edit_jenkins_settings, {:jenkins_settings => [:save_settings]}
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :jenkins, { controller: 'jenkins', action: 'index' }, caption: :label_ci_cd, after: :repository, param: :project_id
  end

  activity_provider :build_activity, default: true, class_name: ['JenkinsBuild']

end
