#!/usr/bin/env rspec

# Copyright (c) [2020-2021] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../../test_helper"
require_relative "examples"
require_relative "matchers"

require "y2partitioner/widgets/menus/view"

describe Y2Partitioner::Widgets::Menus::View do
  subject(:menu) { described_class.new }

  let(:graphical) { true }

  let(:issues_manager) { instance_double(Y2Storage::IssuesManager, probing_issues: issues) }
  let(:devicegraph) { instance_double(Y2Storage::Devicegraph, issues_manager: issues_manager) }
  let(:device_graphs) { instance_double(Y2Partitioner::DeviceGraphs, system: devicegraph) }

  let(:issues) { Y2Issues::List.new }

  before do
    allow(Y2Partitioner::Dialogs::DeviceGraph).to receive(:supported?).and_return(graphical)
    allow(Y2Partitioner::DeviceGraphs).to receive(:instance).and_return(device_graphs)
  end

  include_examples "Y2Partitioner::Widgets::Menus"

  describe "#items" do
    it "includes entries for installation summary, settings and csets" do
      expect(subject.items).to include(item_with_id(:installation_summary))
      expect(subject.items).to include(item_with_id(:settings))
      expect(subject.items).to include(item_with_id(:bcache_csets))
      expect(subject.items).to include(item_with_id(:system_issues))
    end

    context "in graphical mode" do
      let(:graphical) { true }

      it "includes the entry to display the Device Graphs" do
        expect(subject.items).to include(item_with_id(:device_graphs))
      end
    end

    context "in an already installed system" do
      let(:graphical) { false }

      it "does not include the entry to display de Device Graphs" do
        expect(subject.items).to_not include(item_with_id(:device_graphs))
      end
    end
  end

  describe "#disabled_items" do
    context "if there are issues" do
      let(:issues) { Y2Issues::List.new([Y2Storage::Issue.new("Issue 1")]) }

      it "returns an empty array, since all present entries are enabled" do
        expect(menu.disabled_items).to eq []
      end
    end

    context "if there are no issues" do
      let(:issues) { Y2Issues::List.new }

      it "returns :system_issues" do
        expect(menu.disabled_items).to contain_exactly(:system_issues)
      end
    end
  end

  describe "#handle" do
    RSpec.shared_examples "handle dialog" do |dialog_class|
      let(:dialog) { double("Dialog", run: dialog_result) }
      let(:dialog_result) { :whatever }
      before { allow(dialog_class).to receive(:new).and_return dialog }

      it "opens the corresponding dialog (#{dialog_class})" do
        expect(dialog_class).to receive(:new)
        expect(dialog).to receive(:run)
        menu.handle(id)
      end

      context "if the dialog returns :finish" do
        let(:dialog_result) { :finish }

        it "returns nil" do
          expect(menu.handle(id)).to be_nil
        end
      end

      context "if the dialog returns :next" do
        let(:dialog_result) { :next }

        it "returns nil" do
          expect(menu.handle(id)).to be_nil
        end
      end

      context "if the dialog returns any different result" do
        let(:dialog_result) { nil }

        it "returns nil" do
          expect(menu.handle(id)).to be_nil
        end
      end
    end

    context "when :device_graphs was selected" do
      let(:id) { :device_graphs }
      include_examples "handle dialog", Y2Partitioner::Dialogs::DeviceGraph
    end

    context "when :installation_summary was selected" do
      let(:id) { :installation_summary }
      include_examples "handle dialog", Y2Partitioner::Dialogs::SummaryPopup
    end

    context "when :settings was selected" do
      let(:id) { :settings }
      include_examples "handle dialog", Y2Partitioner::Dialogs::Settings
    end

    context "when :bcache_csets was selected" do
      let(:id) { :bcache_csets }
      include_examples "handle dialog", Y2Partitioner::Dialogs::BcacheCsets
    end

    context "when :system_issues was selected" do
      let(:id) { :system_issues }
      include_examples "handle dialog", Y2Partitioner::Dialogs::ProbingIssues
    end
  end
end
