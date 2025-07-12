#!/usr/bin/env ruby

require "thor"
require "json"
require "date"

class ExpenseTracker < Thor
	EXPENSE_FILE = "expense_file.json"

	desc "add --description DESC --amount AMOUNT", "Add a new expense"
	
	option :description, aliases: "-d", require: true, type: :string
	option :amount, aliases: "-a", require: true, type: :numeric

	def add
		description = options[:description]
		amount	= options[:amount]

		if amount < 0
			puts "Amount must be positive"
			exit!
		end
		create_expense(description, amount)
	end

	desc "list", "List all expenses"
	
	def list
		puts "ID | DATE       | DESCRIPTION        | AMOUNT"
		puts "-" * 50

		expenses.each do |e|
			puts "#{e["id"]}  | #{e["date"]} | #{e["description"].ljust(18)} | $#{e["amount"]}"
		end
	end

	desc "summary --month MONTH", "list the total amount"
	option :month, aliases: "-m", required: false, type: :numeric
	
	def summary
		total_amount = 0
		month = options[:month]

		filtered = filter_date(month)

		if filtered.empty?
			puts month ? "No expenses found for month #{month}." : "No expenses found."
		else
			filtered.each { |e| total_amount += e["amount"] }
		  puts "💰 Total expenses#{month ? " for month #{month}" : ""}: $#{'%.2f' % total_amount}"
		end
	end

	desc "delete --id ID", "Delete an expense"
	option :id, aliases: "-d", required: true, type: :numeric

	def delete
		id = options[:id].to_i
		array_size = expenses.count
		expenses.delete_if { |expense| expense["id"] == id}
		save_expenses
		expenses.size < array_size ? puts("deleted correctly") : puts("error deleting")
	end

	private

	def filter_date(month)
		month ? expenses.select { |e| Date.parse(e["date"]).month == month } : expenses
	end

	def create_expense(description, amount)
		expenses << create_expense_hash(description, amount)
		save_expenses
		puts "Expense saved correctly! (ID: #{expenses.last["id"]})"
	end

	def create_expense_hash(description, amount)
		{
			"id" => generate_id,
			"description" => description,
			"amount" => amount,
			"date" => generate_date
		}
	end

	def generate_date
		Time.now.strftime("%Y-%m-%d")
	end

	def generate_id
		return 0 if expenses.empty?
		expenses.map { |e| e["id"] }.max + 1

	end

	def expenses
		@expenses ||= load_expensses
	end

	def load_expensses
	  File.exist?(EXPENSE_FILE) ? JSON.parse(File.read(EXPENSE_FILE)) : []
	end

	def save_expenses
		File.write(EXPENSE_FILE, JSON.pretty_generate(expenses))
	rescue ParserError => e
		puts "Error saving the expense: #{e}"
	end
end

ExpenseTracker.start(ARGV) if $PROGRAM_NAME == __FILE__
