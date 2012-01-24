class IconsController < ApplicationController
  def show
    # Set encoding
    Encoding.default_external = Encoding::BINARY
    
    # Split parameter into the name and id
    arr = params[:id].split(/-/)
    icon_index = 0
    icon_index = arr.pop().to_i if arr.length > 1 && arr.last.index(/^\d+$/)
    name = arr.join('-')
    
    # Setup a place to store the SVG data
    svg_data = nil
    error_message = "An error occurred."
    
    # Grab the noun's page.
    agent = Mechanize.new()
    agent.get("http://thenounproject.com/noun/#{name}/") do |page|
      # Retrieve a list of all icons available
      items = page.parser.css('ul.thumbnails li')
      
      # Retrieve the item
      if icon_index < items.length
        icon_id = items[icon_index]['id'].match(/\d+$/).to_s
        
        # Write zip to temp file
        Tempfile.open(['icon-', '.zip']) do |f|
          file = agent.get("http://thenounproject.com/download/zipped/svg_#{icon_id}.zip")
          File.open(f.path, 'wb') {|f| f.write(file.body) }
          
          # Extract SVG from zip file
          ::Zip::ZipFile.open(f.path) do |zipfile|
            zipfile.get_input_stream("noun_project_#{icon_id}.svg") do |zio|
              svg_data = zio.read
            end
          end
        end
      else
        error_message = "Invalid icon index: #{icon_index} of #{items.length}"
      end
    end
    
    # If we couldn't find the SVG data then return a 404
    if svg_data.nil?
      render :status => 404
    
    # Otherwise return the SVG
    else
      if params[:format] == 'svg'
        render :text => svg_data
      end
    end
  end
end