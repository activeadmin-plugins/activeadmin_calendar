# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Views::IndexAsCalendar do
  it "registers itself as the :calendar index style" do
    expect(described_class.index_name).to eq("calendar")
  end

  it "is registered in ActiveAdmin views" do
    expect(ActiveAdmin::Views::IndexAsCalendar).to be < ActiveAdmin::Component
  end
end
