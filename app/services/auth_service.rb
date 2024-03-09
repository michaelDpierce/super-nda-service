# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

class AuthService
  attr_reader :result
  attr_reader :status

  def initialize
    @result = {}
    @status = :ok
  end

  def find_or_create_user_by(token:)
    sdk       = Clerk::SDK.new
    payout    = sdk.decode_token(token)
    user_data = sdk.users.find(payout["sub"])

    remove_upcase_email_user(user_data)
    remove_duplicate_email_user(user_data)

    @user = find_user_by_source(user_data)
    @user = create_user_by_source(user_data) if @user.nil?

    if @user.present?
      return @user
    end
  rescue StandardError
    @status = :unprocessable_entity
  end

  private

  def find_user_by_source(data)
    Rails.logger.info data

    user = User.find_by(source_id: data["id"])

    if user.nil?
      user = User.find_by(email: data["email_addresses"].first["email_address"])

      if user
        user.source_id = data["id"]
        user.save
      end
    end

    Rails.logger.info "user already exists"

    return user
  end

  def remove_upcase_email_user(data)
    email         = data["email_addresses"].first["email_address"]
    users         = User.where("upper(email) = ?", email.upcase)
    user          = users.reject {|item| item.email == email}.first
    user_ids      = users.map(&:id)
    project_users = ProjectUser.where("user_id IN (?)", user_ids)
    uniq_user_ids = project_users.map(&:user_id).uniq
    
    if uniq_user_ids.length == 1
      removalble_user = user_ids - uniq_user_ids
      User.find(removalble_user.first).destroy
    end
  rescue Exception => e
    puts e.message
  end

  def remove_duplicate_email_user(data)
    email = data["email_addresses"].first["email_address"]

    users         = User.where("lower(email) = ?", email.downcase)
    user          = users.reject {|item| item.email == email}.first
    user_ids      = users.map(&:id)
    project_users = ProjectUser.where("user_id IN (?)", user_ids)
    uniq_user_ids = project_users.map(&:user_id).uniq
    
    if uniq_user_ids.length == 1
      removalble_user = user_ids - uniq_user_ids
      User.find(removalble_user.first).destroy
    end
  rescue Exception => e
    puts e.message
  end

  def create_user_by_source(data)
    User.create!(
      email: data["email_addresses"].first["email_address"],
      first_name: data["first_name"],
      last_name: data["last_name"],
      source_id: data["id"]
    )
  end
end
