# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@supernda.com"
  layout "mailer"

  def project_access_email(user_id, project_id)
    @user    = User.find(user_id)
    @project = Project.find(project_id)

    @url =
      "#{ENV['APP_PROTOCOL']}://#{ENV['APP_HOST']}/projects/#{@project.hashid}?utm_medium=email&utm_source=project_access_email"

    subject = "Project #{@project.name} access has been granted on SuperNDA"

    mail(to: @user.email, subject: subject)
  end
end
