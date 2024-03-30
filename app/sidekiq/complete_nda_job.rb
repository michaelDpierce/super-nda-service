# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class CompleteNdaJob
  require "combine_pdf"
  require "prawn"
  require "prawn/table"

  include Sidekiq::Job

  def perform(document_id, user_id)
    Rails.logger.info "CompleteNDAJob for document_id: #{document_id}"
    Rails.logger.info "CompleteNDAJob for user_id: #{user_id}"
    
    original_document = Document.find(document_id)
    user              = User.find(user_id)
    group             = original_document.group
    project           = original_document.project
    
    party_signature         = user.signature&.download
    counter_party_signature = original_document.counter_party_signature&.download # TODO move to doing this on the group level

    # Duplicate the original document for a new group context
    new_document = original_document.dup

    new_document.owner = nil
    new_document.project_id = group.project_id

    new_document.converted_file.attach(
      io: StringIO.new(original_document.converted_file.download),
      filename: original_document.converted_file.filename.to_s,
      content_type: original_document.converted_file.content_type
    )
    
    new_document.save!

    blob = new_document.converted_file.blob

    party_data = [
      ["Name",  new_document.party_full_name],
      ["Email", new_document.party_email],
      ["Date",  new_document.party_date.strftime("%Y-%m-%d %H:%M:%S %Z")],
      ["IP",    new_document.party_ip],
      ["Agent", new_document.party_user_agent],
      ["Security", "Authenticated"],
      ["Disclosure", "None"]
    ]

    counter_party_data = [
      ["Name",  new_document.counter_party_full_name],
      ["Email", new_document.counter_party_email],
      ["Date",  new_document.counter_party_date.strftime("%Y-%m-%d %H:%M:%S %Z")],
      ["IP",    new_document.counter_party_ip],
      ["Agent", new_document.counter_party_user_agent],
      ["Security", "Passcode"],
      ["Disclosure", "None"]
    ]

    # Step 1: Retrieve the existing PDF from ActiveStorage
    existing_pdf_tempfile = Tempfile.new([blob.filename.base, blob.filename.extension_with_delimiter])
    existing_pdf_tempfile.binmode
    blob.download { |chunk| existing_pdf_tempfile.write(chunk) }
    existing_pdf_tempfile.rewind

    # Step 2: Generate a new PDF (in this example, with Prawn)
    new_pdf_tempfile = Tempfile.new(["new", ".pdf"])

    Prawn::Document.generate(new_pdf_tempfile.path) do |pdf|
      page_title(pdf, "Signed Completion Certification")
      page_space(pdf, 20)
    
      page_text(pdf, "Document Unique ID", new_document.hashid)
      page_text(pdf, "Document Page Count", new_document.number_of_pages || "-")
      page_text(pdf, "Document Name", blob.filename)

      page_space(pdf, 20)

      page_header(pdf, "Certificate of Completion: Party")
      page_table(pdf, party_data)
      page_space(pdf, 20)

      page_signature(pdf, party_signature)
      page_space(pdf, 20)
    
      page_header(pdf, "Certificate of Completion: Counterparty")
      page_table(pdf, counter_party_data)
      page_space(pdf, 20)

      page_signature(pdf, counter_party_signature)
      page_space(pdf, 20)
    end

    # Step 3: Merge the PDFs
    existing_pdf = CombinePDF.load(existing_pdf_tempfile.path)
    new_pdf = CombinePDF.load(new_pdf_tempfile.path)
    merged_pdf = existing_pdf << new_pdf

    # Step 4: Save the merged PDF back to ActiveStorage
    merged_pdf_tempfile = Tempfile.new(['merged', '.pdf'])
    merged_pdf.save(merged_pdf_tempfile.path)
    merged_pdf_tempfile.rewind

    filename = "#{project.name}_#{group.name}_NDA_V#{new_document.version_number}_SIGNED.pdf"
    clean_filename = sanitize_filename(filename)

    # Replace the existing attachment with the merged PDF
    new_document.signed_pdf.attach(
      io: File.open(merged_pdf_tempfile.path),
      filename: clean_filename,
      content_type: 'application/pdf'
    )

    new_document.save!

    Rails.logger.info "CompleteNDAJob for document_id: #{new_document.id} completed successfully!"

    # Ensure tempfiles are closed and unlinked (deleted)
    ensure_tempfiles_cleanup(
      [existing_pdf_tempfile, new_pdf_tempfile, merged_pdf_tempfile]
    )
  end

  private

  def ensure_tempfiles_cleanup(tempfiles)
    tempfiles.each do |tempfile|
      tempfile.close
      tempfile.unlink # Deletes the tempfile
    end
  end

  def page_space(pdf, space = 20)
    pdf.move_down space
  end

  def page_title(pdf, text)
    # Set the font color to blue
    pdf.fill_color "0A558C" # Hex code for blue

    # Render the text in the center, bold and blue
    pdf.text text, align: :center, style: :bold

    # Reset the fill color to black if you're going to add more text in the default color
    pdf.fill_color "000000"
  end

  def page_text(pdf, name, value)
    pdf.fill_color "000000"
    # Use inline_format to allow for HTML-like tags for styling parts of the text
    formatted_text = "<b>#{name}:</b> #{value}"
    pdf.text formatted_text, align: :left, inline_format: true
  end

  def page_header(pdf, text)
    # Container specifications
    container_height = 20
    container_width = pdf.bounds.width
    brand_color = "0A558C" # A deep blue color
    left_padding = 5 # px

    # Start drawing from the current cursor position
    current_cursor = pdf.cursor

    # Set the background color for the container and draw the rectangle
    pdf.fill_color brand_color
    pdf.fill_rectangle [0, current_cursor], container_width, container_height

    # Calculate vertical centering
    # Assuming the font size is 12 points (adjust as needed)
    font_size = 12
    pdf.font_size = font_size
    pdf.fill_color "FFFFFF" # White text color
    vertical_padding = (container_height - font_size) / 2
    text_y_position = current_cursor - vertical_padding - font_size

    # Since text_box auto centers vertically if height is enough, adjust y-position accordingly
    # Note: This approach simplifies vertical centering by leveraging the text_box's height
    text_box_y_position = current_cursor - container_height

    # Use a text_box for more control, including automatic vertical alignment within the box
    pdf.text_box text, {
      at: [left_padding, text_box_y_position + container_height],
      width: container_width - left_padding,
      height: container_height,
      align: :left,
      valign: :center,
      overflow: :shrink_to_fit
    }

    # Reset the fill color to black for the text
    pdf.fill_color "000000"

    # Adjust cursor position if you're adding more content below
    pdf.move_cursor_to current_cursor - container_height
  end

  def page_table(pdf, data)
    full_width = pdf.bounds.width
  
    left_column_width = full_width * 0.3
    right_column_width = full_width * 0.7
  
    pdf.table(data, column_widths: [left_column_width, right_column_width], width: full_width) do |table|
      table.cells.padding = 5
      table.cells.borders = [:top, :bottom, :left, :right]

      table.column(0).align = :right
      table.column(0).font_style = :bold
    end
  end

  def page_signature(pdf, signature)
    if signature
      pdf.image StringIO.new(signature), width: 100, height: 50
    else
      pdf.text "Missing Signature", size: 12
    end
  end

  def sanitize_filename(filename)
    filename.gsub(/[^a-zA-Z0-9\-_.]/, '_')
  end
end