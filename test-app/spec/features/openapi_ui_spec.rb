# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'swagger-ui', :js do
  scenario 'browsing api-docs' do
    skip "Needs work to run on others' machines"
    visit '/api-docs'

    aggregate_failures('verifying page content') do
      expect(page).to have_content('GET /blogs Searches blogs', normalize_ws: true)
      expect(page).to have_content('POST /blogs Creates a blog', normalize_ws: true)
      expect(page).to have_content('GET /blogs/{id} Retrieves a blog', normalize_ws: true)
    end
  end
end
