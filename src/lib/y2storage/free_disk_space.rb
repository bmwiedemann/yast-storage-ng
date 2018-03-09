#!/usr/bin/env ruby
#
# encoding: utf-8

# Copyright (c) [2015] SUSE LLC
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

require "yast"
require "storage"
require "y2storage/disk_size"

module Y2Storage
  # Helper class to keep information about free disk space together.
  # That objects can represent an unpartitioned chunk (maybe within
  # and extended partition) or the space of a partition to be reused.
  class FreeDiskSpace
    # @!attribute disk
    #   @return [DiskSize]
    attr_reader :disk

    # @!attribute region
    #   @return [Region]
    attr_reader :region

    # Constructor
    #
    # @param disk [Disk]
    # @param region [Region]
    def initialize(disk, region)
      @disk = disk
      # Store a duplicate of the original region, which could change or be
      # deleted (don't trust the garbage collector when SWIG is involved)
      region = Storage::Region.new(region.to_storage_value)
      @region = Y2Storage::Region.new(region)
    end

    # Whether the region belongs to a partition that is going to be reused
    #
    # @return [Boolean]
    def reused_partition?
      disk.partitions.map(&:region).include?(region)
    end

    # Return the name of the disk this slot is on.
    #
    # @return [String] disk_name
    def disk_name
      @disk.name
    end

    # Return the size of this slot.
    #
    # @return [DiskSize]
    def disk_size
      region.size
    end

    # Offset of the slot relative to the beginning of the disk
    #
    # @return [DiskSize]
    def start_offset
      region.block_size * region.start
    end

    # Grain for alignment
    #
    # The align grain is the size unit that must be used to specify beginning and
    # end of a partition in order to keep everything aligned.
    #
    # @return [DiskSize]
    def align_grain
      @align_grain ||= disk.as_not_empty { disk.partition_table.align_grain }
    end

    # Whether the partitions should be end-aligned.
    # @see Y2Storage::PartitionTables::Base#require_end_alignment?
    #
    # @return [Boolean]
    def require_end_alignment?
      @end_alignment ||= disk.as_not_empty { disk.partition_table.require_end_alignment? }
    end

    def to_s
      "#<FreeDiskSpace disk_name=#{disk_name}, size=#{disk_size}, start_offset=#{start_offset}>"
    end
  end
end
