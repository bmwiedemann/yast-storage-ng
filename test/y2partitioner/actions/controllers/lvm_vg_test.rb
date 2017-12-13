#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2017] SUSE LLC
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
require "y2partitioner/device_graphs"
require "y2partitioner/actions/controllers/lvm_vg"

describe Y2Partitioner::Actions::Controllers::LvmVg do
  using Y2Storage::Refinements::SizeCasts

  before do
    devicegraph_stub("complex-lvm-encrypt.yml")
  end

  subject(:controller) { described_class.new }

  let(:current_graph) { Y2Partitioner::DeviceGraphs.instance.current }

  def dev(name)
    result = Y2Storage::BlkDevice.find_by_name(current_graph, name)
    result ||= Y2Storage::LvmVg.all(current_graph).find { |i| i.name == name }
    result
  end

  describe "#initialize" do
    it "sets vg name equal to \"\" as default value" do
      expect(controller.vg_name).to eq("")
    end

    it "sets extent size equal to 4 MiB as default value" do
      expect(controller.extent_size).to eq(4.MiB)
    end

    it "creates a new vg" do
      previous_vgs = current_graph.lvm_vgs
      described_class.new
      current_vgs = current_graph.lvm_vgs

      expect(current_vgs.size).to eq(previous_vgs.size + 1)
    end
  end

  describe "#extent_size=" do
    context "with a correct size representation" do
      it "sets the equivalent DiskSize" do
        controller.extent_size = "1 MiB"
        expect(controller.extent_size).to eq(1.MiB)
      end
    end

    context "with an incorrect size representation" do
      it "sets nil" do
        controller.extent_size = "1 bad size"
        expect(controller.extent_size).to be_nil
      end
    end
  end

  describe "#vg_size" do
    it "returns the size of the vg" do
      expect(controller.vg).to receive(:size).and_return Y2Storage::DiskSize.new(1254)
      expect(controller.vg_size).to eq Y2Storage::DiskSize.new(1254)
    end
  end

  describe "#apply_values" do
    it "sets the current vg name" do
      allow(controller).to receive(:vg_name).and_return("new_vg")
      controller.apply_values
      expect(controller.vg.vg_name).to eq("new_vg")
    end

    it "sets the current extent size" do
      allow(controller).to receive(:extent_size).and_return(8.MiB)
      controller.apply_values
      expect(controller.vg.extent_size).to eq(8.MiB)
    end
  end

  describe "#vg_name_errors" do
    before do
      allow(controller).to receive(:vg_name).and_return(value)
    end

    let(:value) { nil }

    it "returns an array" do
      expect(controller.vg_name_errors).to be_a(Array)
    end

    context "when vg name is nil" do
      let(:value) { nil }

      it "contains a message for empty vg name" do
        errors = controller.vg_name_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/Enter a name/)
      end
    end

    context "when vg name is an empty string" do
      let(:value) { "" }

      it "contains a message for empty vg name" do
        errors = controller.vg_name_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/Enter a name/)
      end
    end

    context "when the vg name contains illegal characters" do
      let(:value) { "vg_name$" }

      it "contains a message for illegal vg name" do
        errors = controller.vg_name_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/contains illegal characters/)
      end
    end

    context "when there is other device with the same name" do
      let(:value) { "sda" }

      it "contains a message for duplicated vg name" do
        errors = controller.vg_name_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/another entry in the \/dev/)
      end
    end

    context "when the vg name only contains alphanumeric characters, " \
            " \".\", \"_\", \"-\" and \"+\" and it is not duplicated" do
      let(:value) { "vg.n_a-me+" }

      it "returns an empty list" do
        errors = controller.vg_name_errors
        expect(errors).to be_empty
      end
    end
  end

  describe "#extent_size_errors" do
    before do
      allow(controller).to receive(:extent_size).and_return(value)
    end

    context "when the extent size is nil" do
      let(:value) { nil }

      it "contains a message for invalid extent size" do
        errors = controller.extent_size_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/data entered is invalid/)
      end
    end

    context "when the extent size is less than 1 KiB" do
      let(:value) { 0.5.KiB }

      it "contains a message for invalid extent size" do
        errors = controller.extent_size_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/data entered is invalid/)
      end
    end

    context "when the extent size is not multiple of 128 KiB" do
      let(:value) { 10.KiB }

      it "contains a message for invalid extent size" do
        errors = controller.extent_size_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/data entered is invalid/)
      end
    end

    context "when the extent size is not power of two" do
      let(:value) { 6.MiB }

      it "contains a message for invalid extent size" do
        errors = controller.extent_size_errors
        expect(errors).to_not be_empty
        expect(errors).to include(/data entered is invalid/)
      end
    end

    context "when the extent size is bigger than 1 KiB, multiple of 128 KiB and power of two" do
      let(:value) { 16.MiB }

      it "returns an empty list" do
        errors = controller.extent_size_errors
        expect(errors).to be_empty
      end
    end
  end

  describe "#available_devices" do
    it "returns an array of block devices" do
      expect(controller.available_devices).to be_an Array
      expect(controller.available_devices).to all be_a(Y2Storage::BlkDevice)
    end

    it "includes devices without partition table" do
      expect(controller.available_devices.map(&:name)).to include("/dev/sdb", "/dev/sdc")
    end

    it "includes devices with an empty partition table" do
      sdb = dev("/dev/sdb")
      sdb.create_partition_table(Y2Storage::PartitionTables::Type::GPT)

      expect(controller.available_devices.map(&:name)).to include("/dev/sdb")
    end

    it "includes devices with unmounted filesystem" do
      sdb = dev("/dev/sdb")
      sdb.create_filesystem(Y2Storage::Filesystems::Type::EXT3)
      sdb.filesystem.mount_point = nil

      expect(controller.available_devices.map(&:name)).to include("/dev/sdb")
    end

    it "excludes devices with partitions" do
      partitioned_disks = ["/dev/sda", "/dev/sde", "/dev/sdf"]
      expect(controller.available_devices.map(&:name)).to_not include(*partitioned_disks)
    end

    it "excludes devices with mounted filesystem" do
      sdb = dev("/dev/sdb")
      sdb.create_filesystem(Y2Storage::Filesystems::Type::EXT3)
      sdb.filesystem.mount_point = "/mnt"

      expect(controller.available_devices.map(&:name)).to_not include("/dev/sdb")
    end

    it "excludes devices used as physical volume" do
      expect(controller.available_devices.map(&:name)).to_not include("/dev/sdd")
    end

    # A device is unused when fulfill the previous tested conditions:
    # - has not partitions
    # - formated but not mounted
    # - not used as PV
    it "includes unused disks" do
      expect(controller.available_devices.map(&:name)).to include("/dev/sdb")
    end

    it "includes unused Multipaths" do
      Y2Storage::Multipath.create(current_graph, "/dev/mapper/mp1")
      expect(controller.available_devices.map(&:name)).to include("/dev/mapper/mp1")
    end

    it "includes unused MD Raids" do
      sdb = dev("/dev/sdb")
      md = Y2Storage::Md.create(current_graph, "/dev/md0")
      md.add_device(sdb)

      expect(controller.available_devices.map(&:name)).to include("/dev/md0")
    end

    it "includes unused DM Raids" do
      Y2Storage::DmRaid.create(current_graph, "/dev/mapper/dm1")
      expect(controller.available_devices.map(&:name)).to include("/dev/mapper/dm1")
    end

    it "includes partitions with a linux system ID (linux, LVM, RAID, swap)" do
      devices = controller.available_devices
      expect(devices.map(&:name)).to include("/dev/sda2", "/dev/sda3", "/dev/sda4", "/dev/sde3")
    end

    it "includes partitions with an unmounted filesystem" do
      expect(controller.available_devices.map(&:name)).to include("/dev/sda2", "/dev/sde3")
    end

    it "excludes partitions with a mount point" do
      expect(controller.available_devices.map(&:name)).to include("/dev/sda2", "/dev/sde3")

      sda2 = dev("/dev/sda2")
      sda2.filesystem.mountpoint = "/var"
      sde3 = dev("/dev/sde3")
      sde3.filesystem.mountpoint = "swap"

      expect(controller.available_devices.map(&:name)).to_not include("/dev/sda2", "/dev/sde3")
    end

    it "excludes partitions that are part of an LVM" do
      expect(controller.available_devices.map(&:name)).to_not include("/dev/sde1", "/dev/sde2")
      sda3 = dev("/dev/sda3")
      expect(controller.available_devices).to include sda3

      vg0 = dev("/dev/vg0")
      vg0.add_lvm_pv(sda3)
      expect(controller.available_devices).to_not include sda3
    end

    it "excludes partitions that are part of a MD Raid" do
      sda3 = dev("/dev/sda3")
      expect(controller.available_devices).to include sda3

      new_md = Y2Storage::Md.create(current_graph, "/dev/md0")
      new_md.add_device(sda3)
      expect(controller.available_devices).to_not include sda3
    end
  end

  describe "#devices_in_vg" do
    let(:cr_sdc) { dev("/dev/mapper/cr_sdc") }
    let(:sda3) { dev("/dev/sda3") }

    before do
      controller.vg.add_lvm_pv(cr_sdc)
      controller.vg.add_lvm_pv(sda3)
    end

    it "returns an array with all the devices in the vg used as physical volumes" do
      expect(controller.devices_in_vg).to be_an Array
      expect(controller.devices_in_vg).to all be_a(Y2Storage::BlkDevice)
      expect(controller.devices_in_vg.size).to eq 2
    end

    it "includes the devices directly used by the vg" do
      expect(controller.devices_in_vg).to include sda3
    end

    it "includes the devices used by the vg through an encryption device" do
      expect(controller.devices_in_vg).to include cr_sdc.blk_device
    end

    it "does not include the encryption devices used by the vg" do
      expect(controller.devices_in_vg).to_not include cr_sdc
    end
  end

  describe "#add_device" do
    let(:sdc) { dev("/dev/sdc") }
    let(:sda2) { dev("/dev/sda2") }
    let(:sda3) { dev("/dev/sda3") }
    let(:sda4) { dev("/dev/sda4") }

    before do
      sdc.remove_descendants
      controller.vg.add_lvm_pv(sdc)
    end

    it "adds the device to the vg as physical volume" do
      controller.add_device(sda2)
      expect(controller.devices_in_vg).to include(sda2)
    end

    it "does not remove any previous physical volume" do
      controller.add_device(sda2)
      expect(controller.devices_in_vg).to include(sdc)
    end

    it "causes the device to not be available" do
      expect(controller.available_devices).to include(sda2)
      controller.add_device(sda2)
      expect(controller.available_devices).to_not include(sda2)
    end

    it "raises an exception if the device is already in the vg" do
      controller.add_device(sda2)
      expect { controller.add_device(sda2) }.to raise_error(ArgumentError)
    end

    it "deletes the previous filesystem from the device" do
      expect(sda2.filesystem).to_not be_nil
      controller.add_device(sda2)
      expect(sda2.filesystem).to be_nil
    end

    it "removes the previous encryption from the device" do
      expect(sda4.encrypted?).to eq(true)
      controller.add_device(sda4)
      expect(sda4.encrypted?).to eq(false)
    end

    it "sets the partition identifier to LVM" do
      controller.add_device(sda3)
      controller.add_device(sda4)
      expect(sda3.id.is?(:lvm)).to eq true
      expect(sda4.id.is?(:lvm)).to eq true
    end
  end

  describe "#remove_device" do
    let(:sdc) { dev("/dev/sdc") }
    let(:sda2) { dev("/dev/sda2") }

    before do
      controller.add_device(sdc)
      controller.add_device(sda2)
    end

    it "removes the device from the vg physical volumes" do
      expect(controller.devices_in_vg).to include sda2
      controller.remove_device(sda2)
      expect(controller.devices_in_vg).to_not include sda2
    end

    it "does not remove any other device from vg physical volumes" do
      controller.remove_device(sda2)
      expect(controller.devices_in_vg).to include sdc
    end

    it "makes the device available" do
      expect(controller.available_devices).to_not include sda2
      controller.remove_device(sda2)
      expect(controller.available_devices).to include sda2
    end

    it "raises an exception if trying to remove a device that is not in the vg physical volumes" do
      controller.remove_device(sda2)
      expect { controller.remove_device(sda2) }.to raise_error(ArgumentError)
    end
  end
end
