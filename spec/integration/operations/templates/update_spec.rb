# frozen_string_literal: true

require "fileutils"

RSpec.describe "update templates operation" do
  let(:bin_path) {
    Pathname.new(File.expand_path("../../../../../bin", __FILE__))
  }

  let(:support_path) {
    Pathname.new(File.expand_path("../update/support/simple", __FILE__))
  }

  let(:generated) {
    [
      support_path.join("my-gem.gemspec")
    ]
  }

  def generate
    Dir.chdir(support_path) do
      load(bin_path.join("update-templates"))
    end
  end

  after do
    generated.each do |path|
      if path.file?
        FileUtils.rm(path)
      elsif path.directory?
        FileUtils.rm_r(path)
      end
    end
  end

  describe "generating files from templates" do
    it "creates each defined template" do
      generate

      expect(support_path.join("my-gem.gemspec").exist?).to be(true)
    end

    it "builds each template in context of the operation" do
      generate

      # The template wouldn't have access to config if it's compiled in the wrong context.
      #
      expect(support_path.join("my-gem.gemspec").read).to include_sans_whitespace(
        <<~CONTENT
          spec.name = "my-gem"
        CONTENT
      )
    end

    context "template is configured with a nested path" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/nested", __FILE__))
      }

      let(:generated) {
        [
          support_path.join("foo")
        ]
      }

      it "generates a file named after the template" do
        generate

        expect(support_path.join("foo/bar/itsa.gemspec").exist?).to be(true)
      end
    end

    context "template is configured without a path" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/pathless", __FILE__))
      }

      let(:generated) {
        [
          support_path.join("my-gem.gemspec")
        ]
      }

      it "generates at the root scope" do
        generate

        expect(support_path.join("my-gem.gemspec").exist?).to be(true)
      end
    end

    context "template is configured with a path to a directory" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/directory", __FILE__))
      }

      let(:generated) {
        [
          support_path.join("nested")
        ]
      }

      it "generates a file named after the template" do
        generate

        expect(support_path.join("nested/my-gem.gemspec").exist?).to be(true)
      end
    end

    context "template does not exist" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/missing", __FILE__))
      }

      it "raises an error" do
        expect {
          generate
        }.to raise_error(Errno::ENOENT) do |error|
          expect(error.message).to include("No such file or directory")
          expect(error.message).to include("update/support/missing/.commit/templates/my-gem.gemspec.erb")
        end
      end
    end

    context "template fails to compile" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/failed", __FILE__))
      }

      it "raises an error" do
        expect {
          generate
        }.to raise_error(NameError)
      end
    end
  end

  describe "committing and pushing the changes" do
    it "invokes the commit and push operation" do
      expect(Commit::Operations::Git::Commit).to receive(:call) do |**kwargs|
        expect(kwargs[:message]).to eq("update templates")
      end

      expect(Commit::Operations::Git::Push).to receive(:call)

      generate
    end
  end
end