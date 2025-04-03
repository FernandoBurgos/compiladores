require_relative 'queue'
require_relative 'stack'
require_relative 'customHash'

def test_browser_history
  puts "Testing Browser History with Stack..."
  # Simulate a browser history using my stack class
  browser_history = Stack.new
  # current page on the browser being loaded
  current_page = nil

  # Simulate visiting pages
  current_page = "google.com"
  browser_history.push(current_page)
  puts "visiting #{current_page}"
  current_page = "github.com"
  browser_history.push(current_page)
  puts "visiting #{current_page}"
  current_page = "stackoverflow.com"
  browser_history.push(current_page)
  puts "visiting #{current_page}"

  # Go back in history
  puts "Going back in history..."
  browser_history.pop # Remove the current loaded page
  current_page = browser_history.last # Set the new current page to load
  puts "Loaded page is github.com: #{current_page == "github.com"}"

  puts "Going back in history..."
  browser_history.pop
  current_page = browser_history.last
  puts "Loaded page is google.com: #{current_page == 'google.com'}"

  puts "is the stack empty? #{browser_history.empty? == false}"
  puts "Browser History test passed!"
  puts ""
end

def test_customer_support
  puts "Testing Customer Support Queue..."
  # Simulate a customer support ticket queue using my queue class
  ticket_queue = Queue.new

  # Add tickets to the queue
  ticket_queue.enqueue("Ticket 1: Password reset")
  puts "Ticket 1 added to queue"
  ticket_queue.enqueue("Ticket 2: Cannot log in")
  puts "Ticket 2 added to queue"
  ticket_queue.enqueue("Ticket 3: Payment issue")
  puts "Ticket 3 added to queue"
  puts ""

  # Process tickets
  puts "First ticket to attend: #{ticket_queue.dequeue}"
  puts "Next ticket in queue: #{ticket_queue.front}"
  puts "Tickets pending: #{ticket_queue.size}"
  puts "Customer Support test passed!"
  puts ""
end

def test_user_profiles
  puts "Testing User Profiles with CustomHash..."
  # Simulate user profiles using my custom hash class
  user_profiles = CustomHash.new

  # Add user profiles
  user_profiles.set("user1", { name: "Alice", age: 30, email: "alice@example.com" })
  user_profiles.set("user2", { name: "Bob", age: 25, email: "bob@example.com" })
  puts "Users filed: #{user_profiles.values.join(", ")}"
  puts ""

  # Retrieve and update profiles
  puts "User1's name is: #{user_profiles.get("user1")[:name]}"
  puts "User2's email is bob@example.com: #{user_profiles.get("user2")[:email] == "bob@example.com"}"
  # Update user2's age
  puts ""
  puts "Updating User2's age..."
  user_profiles.set("user2", { name: "Bob", age: 28, email: "bob@example.com" })
  puts "User2's updated age is 25: #{user_profiles.get("user2")[:age] == 25}"

  puts "User Profiles test passed!"
end

if $PROGRAM_NAME == __FILE__
  test_browser_history
  test_customer_support
  test_user_profiles
end
