# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

class HomeController < ActionController::API
  def welcome
    render json: {
      message: "Welcome to the MinuteBook API",
      questions: "Email matchmike1313@gmail.com for questions"
    }.to_json
  end
end