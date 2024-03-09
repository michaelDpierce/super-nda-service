# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

class HomeController < ActionController::API
  def welcome
    render json: {
      message: "Welcome to the SuperNDA API",
      questions: "Email team@supernda.com for questions"
    }.to_json
  end
end