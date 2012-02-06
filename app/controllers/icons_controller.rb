class IconsController < ApplicationController
  def show
    # Set encoding
    Encoding.default_external = Encoding::BINARY
    
    # Split parameter into the name and id
    options = parse_options(params[:id])
    
    # Setup a place to store the SVG data
    svg_data = nil
    error_message = "An error occurred."
    
    # Grab the noun's page.
    agent = Mechanize.new()
    agent.get("http://thenounproject.com/noun/#{options[:name]}/") do |page|
      # Retrieve a list of all icons available
      items = page.parser.css('ul.thumbnails li')
      
      # Retrieve the item
      if options[:index] < items.length
        icon_id = items[options[:index]]['id'].match(/\d+$/).to_s
        
        # Write zip to temp file
        Tempfile.open(['icon-', '.zip']) do |f|
          file = agent.get("http://thenounproject.com/download/zipped/svg_#{icon_id}.zip")
          File.open(f.path, 'wb') {|f| f.write(file.body) }
          
          # Extract SVG from zip file
          ::Zip::ZipFile.open(f.path) do |zipfile|
            zipfile.get_input_stream("noun_project_#{icon_id}.svg") do |zio|
              svg_data = Nokogiri::XML(zio.read)
            end
          end
        end
      else
        error_message = "Invalid icon index: #{options[:index]} of #{items.length}"
      end
    end
    
    # If we couldn't find the SVG data then return a 404
    if svg_data.nil?
      render :status => 404
    
    # Otherwise return the SVG
    else
      # Update the SVG color.
      if !options[:color].nil?
        set_svg_fill_color(svg_data, options[:color])
      end

      # Update the SVG dimension.
      if !options[:width].nil? && !options[:height].nil?
        set_svg_size(svg_data, options[:width], options[:height])
      end
      
      # Output SVG.
      if params[:format] == 'svg'
        render :text => svg_data.to_s
      end
    end
  end
  
  
  ##############################################################################
  # Private Methods
  ##############################################################################
  
  ######################################
  # Options
  ######################################
  
  # Retrieves a list of options given an id passed to the controller.
  def parse_options(str)
    options = {}
    items = str.split(/-/)
    
    # The first option is always the name of the icon.
    options[:name] = items.shift()
    while items.length > 0 && items.first.index(/^[a-z]+$/) && !is_color?(items.first)
      options[:name] = "#{options[:name]}-#{items.shift()}"
    end
    options[:name].gsub!(/_/, '-')
    
    # The second option is the index if it is a single integer.
    if !items.first.nil? && !items.first.index(/^\d$/).nil?
      options[:index] = items.shift().to_i
    else
      options[:index] = 0
    end
    
    # The remaining options are determined by format.
    items.each do |item|
      # Color: 3 digit hexidecimal number (e.g. fff).
      if item.index(/^[0-9a-f]{3}$/i)
        options[:color] = item.downcase.chars.map {|x| x*2}.join('')

      # Color: 6 digit hexidecimal number (e.g. ffffff).
      elsif item.index(/^[0-9a-f]{6}$/i)
        options[:color] = item.downcase
        
      # Size: Two number joined by an 'x'
      elsif item.index(/^\d+x\d+$/)
        width, height = item.split('x').map {|x| x.to_i}
        options[:width]  = width
        options[:height] = height
      end
    end
    
    # Return options
    return options
  end

  def is_color?(str)
    return !str.index(/^[0-9a-f]{3}$/).nil? || !str.index(/^[0-9a-f]{6}$/).nil?
  end
  

  ######################################
  # SVG
  ######################################
  
  # Changes the fill color of the SVG drawing.
  def set_svg_fill_color(xml, color)
    xml.root['style'] = "fill:##{color}"
    
    # Strip existing fills.
    xml.root.children.each do |child|
      child['fill'] = ''
    end
  end

  # Changes the size of the SVG drawing.
  def set_svg_size(xml, width, height)
    # Save original dimension and calculate percent change.
    orig = {width:xml.root['width'].to_f, height:xml.root['height'].to_f}
    delta = {width:width.to_f/orig[:width], height:height.to_f/orig[:height]}
    
    # Set new width & height.
    xml.root['width'] = "#{width}px"
    xml.root['height'] = "#{height}px"
  end
end