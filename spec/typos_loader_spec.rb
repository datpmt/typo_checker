# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'fileutils'
require_relative '../lib/typo_checker'

module TypoChecker
  RSpec.describe TyposLoader do
    let(:file_path) { 'spec/fixtures/typos.csv' }
    let(:skips) { %w[teh recieve] }
    let(:typos_loader) { TyposLoader.new(skips) }

    describe '#load_typos' do
      context 'when the CSV contains typos and the skip list is non-empty' do
        before do
          # Prepare the test CSV content
          CSV.open(file_path, 'w') do |csv|
            csv << %w[teh the]
            csv << %w[recieve receive]
            csv << %w[misteak mistake]
          end
        end

        after do
          File.delete(file_path) if File.exist?(file_path)
        end

        it 'loads typos and skips the entries in the skips list' do
          result = typos_loader.load_typos(file_path)

          expect(result).to eq(
            {
              'misteak' => 'mistake'
            }
          )
        end
      end

      context 'when the CSV file is empty' do
        before do
          # Create an empty CSV file
          CSV.open(file_path, 'w')
        end

        after do
          File.delete(file_path) if File.exist?(file_path)
        end

        it 'returns an empty hash' do
          result = typos_loader.load_typos(file_path)
          expect(result).to eq({})
        end
      end

      context 'when the skip list is empty' do
        let(:skips) { [] } # Empty skips list
        let(:typos_loader) { TyposLoader.new(skips) }

        before do
          # Prepare the test CSV content
          CSV.open(file_path, 'w') do |csv|
            csv << %w[teh the]
            csv << %w[recieve receive]
            csv << %w[misteak mistake]
          end
        end

        after do
          File.delete(file_path) if File.exist?(file_path)
        end

        it 'loads all the typos from the CSV' do
          result = typos_loader.load_typos(file_path)

          expect(result).to eq(
            {
              'teh' => 'the',
              'recieve' => 'receive',
              'misteak' => 'mistake'
            }
          )
        end
      end
    end
  end
end
