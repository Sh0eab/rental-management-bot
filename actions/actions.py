from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet, FollowupAction
import re
import difflib
from .database import db

class ActionSearchRooms(Action):
    def name(self) -> Text:
        return "action_search_rooms"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        location = tracker.get_slot("location")
        budget = tracker.get_slot("budget")
        preferences = tracker.get_slot("preferences")
        
        if not location:
            dispatcher.utter_message(text="কোন এলাকায় রুম খুঁজছেন? I need to know your preferred location.")
            return []

        if not budget:
            dispatcher.utter_message(text="আপনার বাজেট কত? What's your monthly budget?")
            return []

        # Search using database - fallback to demo data if database fails
        try:
            matching_rooms = db.search_properties(location, budget, preferences)
            
            # Log search analytics (only if database is available)
            try:
                db.log_search_analytics(
                    user_id=None,  # You can get user_id from session later
                    location=location,
                    budget=budget,
                    preferences=preferences,
                    results_count=len(matching_rooms)
                )
            except:
                pass  # Ignore analytics logging failures
            
            if matching_rooms:
                response = f"🎉 Found {len(matching_rooms)} room(s) in {location.title()}:\n\n"
                for i, room in enumerate(matching_rooms[:3], 1):
                    response += f"🏠 **Room {i}: {room['neighborhood']}**\n"
                    response += f"💰 ৳{int(room['rent_amount'])}/month\n"
                    response += f"📞 Contact: {room['owner_phone']}\n"
                    response += f"👤 Owner: {room['owner_name']}\n\n"
            else:
                # Fallback to demo data when no database results
                matching_rooms = self._get_demo_rooms(location, budget)
                if matching_rooms:
                    response = f"🎉 Found {len(matching_rooms)} room(s) in {location.title()} (Demo Data):\n\n"
                    for i, room in enumerate(matching_rooms, 1):
                        response += f"🏠 **Room {i}: {room['neighborhood']}**\n"
                        response += f"💰 ৳{room['price']}/month\n"
                        response += f"📞 Contact: {room['contact']}\n\n"
                else:
                    response = f"😔 No rooms found in {location.title()} within ৳{int(budget)}.\n\n"
                    response += "Try:\n• Increasing your budget\n• Different location\n• Checking nearby areas"
                
        except Exception as e:
            print(f"Database error: {e}")
            # Use demo data as fallback
            matching_rooms = self._get_demo_rooms(location, budget)
            if matching_rooms:
                response = f"🎉 Found {len(matching_rooms)} room(s) in {location.title()} (Demo Data):\n\n"
                for i, room in enumerate(matching_rooms, 1):
                    response += f"🏠 **Room {i}: {room['neighborhood']}**\n"
                    response += f"💰 ৳{room['price']}/month\n"
                    response += f"📞 Contact: {room['contact']}\n\n"
            else:
                response = "Sorry, I'm currently having technical difficulties. Please try again later or contact support."
                matching_rooms = []

        dispatcher.utter_message(text=response)
        return [SlotSet("search_results", matching_rooms)]
    
    def _get_demo_rooms(self, location, budget):
        """Fallback demo data when database is not available"""
        demo_rooms = [
            {
                "neighborhood": f"{location.title()} Demo Area",
                "price": 12000,
                "contact": "01712345678",
                "type": "single",
                "furnished": True,
                "occupancy": ["bachelor", "student"],
                "gender_preference": "any",
                "amenities": ["WiFi", "AC", "Parking"],
                "nearby": ["Market", "Bus Stop", "Restaurant"],
                "transportation": ["Bus", "CNG", "Rickshaw"],
                "area_details": f"Central {location.title()}",
                "description": "Well-maintained room in good location",
                "advance": "2 months rent"
            },
            {
                "neighborhood": f"{location.title()} Central",
                "price": 15000,
                "contact": "01812345678",
                "type": "double",
                "furnished": False,
                "occupancy": ["family", "professional"],
                "gender_preference": "any",
                "amenities": ["Parking", "Security", "Generator"],
                "nearby": ["Hospital", "School", "Shopping Mall"],
                "transportation": ["Metro", "Bus", "Taxi"],
                "area_details": f"Prime {location.title()}",
                "description": "Spacious room suitable for families",
                "advance": "1 month rent"
            }
        ]
        
        # Filter by budget
        filtered_rooms = [room for room in demo_rooms if room["price"] <= float(budget) * 1.2]
        return filtered_rooms[:3]

class ActionGetRoomDetails(Action):
    def name(self) -> Text:
        return "action_get_room_details"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        # Get the latest message to extract room number
        latest_message = tracker.latest_message.get('text', '').lower()
        print(f"DEBUG: Latest message: '{latest_message}'")
        
        # Extract room number from user input
        room_number = None
        
        # Check for exact matches first
        if 'room 1' in latest_message or 'first room' in latest_message or latest_message.strip() == '1':
            room_number = 1
        elif 'room 2' in latest_message or 'second room' in latest_message or latest_message.strip() == '2':
            room_number = 2
        elif 'room 3' in latest_message or 'third room' in latest_message or latest_message.strip() == '3':
            room_number = 3
        # Fallback to simple number detection
        elif '1' in latest_message and not any(x in latest_message for x in ['11', '12', '13', '21', '31']):
            room_number = 1
        elif '2' in latest_message and not any(x in latest_message for x in ['12', '21', '22', '23', '32']):
            room_number = 2
        elif '3' in latest_message and not any(x in latest_message for x in ['13', '23', '31', '32', '33']):
            room_number = 3
        
        print(f"DEBUG: Detected room number: {room_number}")
        
        # Get search results from slot
        search_results = tracker.get_slot("search_results")
        print(f"DEBUG: Search results: {search_results}")
        
        if not search_results:
            dispatcher.utter_message(text="Please search for rooms first, then ask for details.")
            return []
        
        if room_number is None or room_number > len(search_results):
            dispatcher.utter_message(text=f"Please specify which room (1-{len(search_results)}) you'd like details for.")
            return []
        
        # Get the selected room
        room = search_results[room_number - 1]
        
        # Create detailed response
        response = f"🏠 **Room {room_number} Details: {room['neighborhood']}**\n\n"
        response += f"📍 **Location:** {room['area_details']}\n"
        response += f"💰 **Price:** ৳{room['price']}/month\n"
        response += f"🏠 **Type:** {room['type'].title()} Room\n"
        response += f"🪑 **Furnished:** {'Yes' if room['furnished'] else 'No'}\n"
        response += f"👥 **Suitable for:** {', '.join(room['occupancy']).title()}\n"
        response += f"🚻 **Gender Preference:** {room['gender_preference'].title()}\n\n"
        
        response += f"🏡 **Amenities:**\n"
        for amenity in room['amenities']:
            response += f"• {amenity}\n"
        
        response += f"\n📍 **Nearby Places:**\n"
        for place in room['nearby']:
            response += f"• {place}\n"
        
        response += f"\n🚗 **Transportation:**\n"
        for transport in room['transportation']:
            response += f"• {transport}\n"
        
        response += f"\n📝 **Description:** {room['description']}\n\n"
        response += f"📞 **Contact:** {room['contact']}\n"
        response += f"💳 **Advance Payment:** {room['advance']}\n"
        
        dispatcher.utter_message(text=response)
        return [SlotSet("selected_room", str(room_number))]

class ActionCompareRooms(Action):
    def name(self) -> Text:
        return "action_compare_rooms"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        search_results = tracker.get_slot("search_results")
        
        if not search_results or len(search_results) < 2:
            dispatcher.utter_message(text="You need at least 2 rooms to compare. Please search for more rooms first.")
            return []
        
        response = "🏠 **Room Comparison:**\n\n"
        
        for i, room in enumerate(search_results[:3], 1):
            response += f"**Room {i}: {room['neighborhood']}**\n"
            response += f"💰 Price: ৳{room['price']}/month\n"
            response += f"🏠 Type: {room['type'].title()}\n"
            response += f"🪑 Furnished: {'Yes' if room['furnished'] else 'No'}\n"
            response += f"👥 Suitable for: {', '.join(room['occupancy'])}\n"
            response += f"📞 Contact: {room['contact']}\n\n"
        
        response += "💡 **Tip:** Ask for specific room details to see more information!"
        
        dispatcher.utter_message(text=response)
        return []

class ActionGetContactInfo(Action):
    def name(self) -> Text:
        return "action_get_contact_info"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        selected_room = tracker.get_slot("selected_room")
        search_results = tracker.get_slot("search_results")
        
        if selected_room and search_results:
            room_number = int(selected_room)
            if room_number <= len(search_results):
                room = search_results[room_number - 1]
                response = f"📞 **Contact Information for Room {room_number}:**\n\n"
                response += f"🏠 **Location:** {room['neighborhood']}\n"
                response += f"📱 **Phone:** {room['contact']}\n"
                response += f"💰 **Price:** ৳{room['price']}/month\n"
                response += f"💳 **Advance:** {room['advance']}\n\n"
                response += "💡 **Tips:**\n"
                response += "• Call during business hours (9 AM - 6 PM)\n"
                response += "• Ask about viewing the room\n"
                response += "• Confirm all details before making payments\n"
                response += "• Always verify the property in person"
            else:
                response = "Please select a valid room number first."
        else:
            response = "Please search for rooms and select one to get contact information."
        
        dispatcher.utter_message(text=response)
        return []

class ActionAreaInformation(Action):
    def name(self) -> Text:
        return "action_area_information"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        location = tracker.get_slot("location")
        selected_room = tracker.get_slot("selected_room")
        search_results = tracker.get_slot("search_results")
        
        if selected_room and search_results:
            room_number = int(selected_room)
            if room_number <= len(search_results):
                room = search_results[room_number - 1]
                response = f"🏙️ **Area Information for {room['neighborhood']}:**\n\n"
                response += f"📍 **Exact Location:** {room['area_details']}\n\n"
                
                response += f"🏪 **Nearby Places:**\n"
                for place in room['nearby']:
                    response += f"• {place}\n"
                
                response += f"\n🚗 **Transportation Options:**\n"
                for transport in room['transportation']:
                    response += f"• {transport}\n"
                
                response += f"\n💡 **Area Highlights:**\n"
                if "TSC" in room['nearby'] or "Dhaka University" in room['nearby']:
                    response += "• Student-friendly area\n"
                if "Market" in str(room['nearby']):
                    response += "• Shopping facilities nearby\n"
                if "Hospital" in str(room['nearby']):
                    response += "• Medical facilities available\n"
                if "Restaurant" in str(room['nearby']):
                    response += "• Food options easily accessible\n"
                
                response += f"\n🏠 **Room Type:** {room['type'].title()}\n"
                response += f"💰 **Price Range:** ৳{room['price']}/month\n"
                response += f"👥 **Suitable for:** {', '.join(room['occupancy']).title()}"
            else:
                response = "Please select a valid room number first."
        elif location:
            response = f"🏙️ **General Information about {location.title()}:**\n\n"
            response += "• Well-connected area with good transportation\n"
            response += "• Markets, restaurants, and essential services nearby\n"
            response += "• Generally safe and residential\n"
            response += "• Good for students and professionals\n\n"
            response += "💡 **Tip:** Search for specific rooms to get detailed area information!"
        else:
            response = "Please search for rooms or specify a location to get area information."
        
        dispatcher.utter_message(text=response)
        return []

class ActionResetSearch(Action):
    def name(self) -> Text:
        return "action_reset_search"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        response = "🔄 Starting fresh search! Where would you like to search for a room?"
        dispatcher.utter_message(text=response)
        
        return [
            SlotSet("location", None),
            SlotSet("budget", None),
            SlotSet("preferences", None),
            SlotSet("search_results", None)
        ]
