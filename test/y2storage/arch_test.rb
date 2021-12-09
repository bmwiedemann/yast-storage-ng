#!/usr/bin/env rspec
# Copyright (c) [2021] SUSE LLC
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

require_relative "spec_helper"
require "y2storage"

describe Y2Storage::Arch do
  subject = described_class

  describe "#new" do
    it "returns a Y2Storage::Arch object" do
      expect(subject.new).to be_a Y2Storage::Arch
    end
  end

  describe "#efiboot?" do
    context "if /etc/install.inf::EFI is set to 1" do
      before do
        allow(Yast::Linuxrc).to receive(:InstallInf).with("EFI").and_return("1")
      end

      it "returns true" do
        expect(subject.new.efiboot?).to eq true
      end
    end

    context "if /etc/install.inf::EFI is set to 0" do
      before do
        allow(Yast::Linuxrc).to receive(:InstallInf).with("EFI").and_return("0")
      end

      it "returns false" do
        expect(subject.new.efiboot?).to eq false
      end
    end
  end
end
