#!/usr/bin/env rspec

# Copyright (c) [2018-2020] SUSE LLC
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
# find current contact information at www.suse.com

require_relative "test_helper"

require "y2partitioner/device_graphs"

describe Y2Partitioner::DeviceGraphs do
  before do
    fake_scenario("mixed_disks")
  end

  subject { described_class.create_instance(system_graph, current_graph) }

  let(:system_graph) { nil }

  let(:current_graph) { nil }

  describe "#disk_analyzer" do
    let(:probed_disk_analyzer) { Y2Storage::StorageManager.instance.probed_disk_analyzer }

    it "retuns a disk analyzer" do
      expect(subject.disk_analyzer).to be_a(Y2Storage::DiskAnalyzer)
    end

    context "when the system graph is the probed one" do
      let(:system_graph) { Y2Storage::StorageManager.instance.probed }

      it "returns the probed disk analyzer" do
        expect(subject.disk_analyzer.object_id).to eq(probed_disk_analyzer.object_id)
      end
    end

    context "when the system graph is not the probed one" do
      context "but it is equal to probed" do
        let(:system_graph) { Y2Storage::StorageManager.instance.probed.dup }

        it "returns the probed disk analyzer" do
          expect(subject.disk_analyzer.object_id).to eq(probed_disk_analyzer.object_id)
        end
      end

      context "and it is not equal to probed" do
        let(:storage) { Y2Storage::StorageManager.instance.storage }
        let(:system_graph) { Y2Storage::Devicegraph.new(storage.create_devicegraph("fake")) }

        it "returns a new disk analyzer" do
          expect(subject.disk_analyzer.object_id).to_not eq(probed_disk_analyzer.object_id)
        end
      end
    end
  end

  describe "#actions?" do
    context "when there are no actions to perform in the current graph" do
      before do
        # Note that adding userdata makes devicegraphs to be not equal when comparing them.
        # Regression for bsc#1179829.
        sdb2 = subject.current.find_by_name("/dev/sdb2")
        sdb2.filesystem.subvolumes_prefix = "@"
      end

      it "returns false" do
        expect(subject.actions?).to eq(false)
      end
    end

    context "when there are actions to perform in the current graph" do
      before do
        sda2 = subject.current.find_by_name("/dev/sda2")
        sda2.delete_filesystem
      end

      it "returns true" do
        expect(subject.actions?).to eq(true)
      end
    end
  end

  describe "#pre_transaction_graph" do
    context "when a transaction was started" do
      it "returns a devicegraph" do
        exist = false

        subject.transaction { exist = subject.pre_transaction.is_a?(Y2Storage::Devicegraph) }

        expect(exist).to eq(true)
      end
    end

    context "when a transaction was finished" do
      it "returns nil" do
        subject.transaction {} # empty trans is enough

        expect(subject.pre_transaction).to be_nil
      end
    end

    context "when a transaction was not started" do
      it "returns nil" do
        expect(subject.pre_transaction).to be_nil
      end
    end
  end
end
