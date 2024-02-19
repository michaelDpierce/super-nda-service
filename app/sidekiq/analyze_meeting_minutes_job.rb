# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require 'openai'

class AnalyzeMeetingMinutesJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform(directory_file_id)
    @directory_file_id = directory_file_id
    @content = build_content

    return if @content.blank?

    @directory_file = DirectoryFile.find(@directory_file_id)

    Rails.logger.info "Content: #{@content}"

    @client = OpenAI::Client.new(access_token: ENV['OPENAI_SECRET_KEY'])

    display_date = extract_display_date
    location     = extract_location
    attendees    = extract_attendees

    Rails.logger.info "display_date: #{display_date}"
    Rails.logger.info "location: #{location}"
    Rails.logger.info "attendees: #{attendees}"

    @directory_file.update(
      openai_display_date: display_date,
      openai_location: location,
      openai_attendance: attendees
    )
  end

  def build_content
    DirectoryFile.select("id, SUBSTRING(content, 1, 3000) AS content_preview")
      .find(@directory_file_id)
      &.content_preview
      &.squish
  end

  def extract_display_date
    question = 'Return onlt the data and time of this meeting in ISO 8601 format in UTC. If there is not a time, return only the date, and if there is not a date or time return nil.'
    
    prompt = <<~PROMPT
      #{@content}
      
      Q: #{question}
      A:
    PROMPT

    response = @client.chat(
      parameters: {
          model:'gpt-3.5-turbo-0125',
          messages: [{ role: 'user', content: prompt}],
          temperature: 0.7,
      }
    )

    raw_display_date = response['choices'][0]['message']['content']

    return raw_display_date.match?(/\A\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}Z?)?\z/) ? raw_display_date : nil
  end

  def extract_location
    question = 'Return only the address for this meeting but format the address as [Street Address], [City], [State/Province/Region], [Postal Code], [Two Digit Country Code, e.g. US]. If there is no address, return N/A.'
    
    prompt = <<~PROMPT
      #{@content}
      
      Q: #{question}
      A:
    PROMPT

    response = @client.chat(
      parameters: {
          model:'gpt-3.5-turbo-0125',
          messages: [{ role: 'user', content: prompt}],
          temperature: 0.7,
      }
    )

    return response['choices'][0]['message']['content']
  end

  def extract_attendees
    question = 'Extract each person that attended this meeting into a comma seperated list. Create a key that concatenates the first and last name of each person, removed all spaces and lowercases all characters.'

    prompt = <<~PROMPT
      #{@content}
      
      Q: #{question}
      A:
    PROMPT

    response = @client.chat(
      parameters: {
          model:'gpt-3.5-turbo-0125',
          messages: [{ role: 'user', content: prompt}],
          temperature: 0.7,
      }
    )

    return response['choices'][0]['message']['content']
  end
end