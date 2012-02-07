class HomeController < ApplicationController
  def index
    # Set cache control.
    response.headers['Cache-Control'] = 'public, max-age=86400'
  end
end