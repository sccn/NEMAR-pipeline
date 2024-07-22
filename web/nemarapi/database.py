import requests 
import os
import urllib3
urllib3.disable_warnings()
requests.packages.urllib3.disable_warnings() 
class NEMARAPI:
	def __init__(self):
		self.api_url = "https://nemar-dev.ucsd.edu/api/dataexplorer/datapipeline"
		self.table_name = "dataexplorer_dataset_pipeline"
		self.default_entries = {'channel_location':None, 
	    						'has_viz':None}
		
		filepath = os.path.abspath(__file__)
		dirpath = os.path.dirname(filepath)
		try:
			with open(dirpath+'/nemar_access_token', 'r') as fin:
				self.access_token = fin.read()
		except OSError as err:
			print("Error: Could not get access token")
			raise err

	def add_ds(self, dsnumber, entries:dict):
		if not set(self.default_entries.keys()) == set(entries.keys()):
			raise ValueError('Not all required entries are provided')

		endpoint = self.api_url
		data = {
			"access_token":self.access_token, 
			"table_name":self.table_name,
			"dataset_id": dsnumber,
			"entry": {
				"id":dsnumber,
				"channel_location":entries['channel_location'],
				"has_viz":entries['has_viz']
			} 
		}

		response = requests.post(endpoint, json=data, headers={'Content-Type': 'application/json'}, verify=False)
		if response.status_code == 200:
			print(response.json())

	def update_ds(self, dsnumber, entries:dict):
		if not set(self.default_entries.keys()) == set(entries.keys()):
			raise ValueError('Not all required entries are provided')

		endpoint = self.api_url + "/update"
		data = {
			"access_token":self.access_token, 
			"table_name":self.table_name,
			"dataset_id": dsnumber,
			"entry": {
				"id":dsnumber,
				"channel_location":entries['channel_location'],
				"has_viz":entries['has_viz']
			} 
		}

		response = requests.put(endpoint, json=data, headers={'Content-Type': 'application/json'}, verify=False)
		if response.status_code == 200:
			print(response.json())


	def get_ds_info(self, dsnumber):
		endpoint = self.api_url + "/read"
		data = {
			"access_token":self.access_token, 
			"table_name":self.table_name,
			"dataset_id":dsnumber,
		}

		response = requests.post(endpoint, json=data, headers={'Content-Type': 'application/json'}, verify=False)
		return response.json()

	def has_entry(self, dsnumber):
		info = self.get_ds_info(dsnumber)
		if "entry" in info and info["entry"]:
			return True
		else:
			return False
	
	def update_ds_status(self, dsnumber, entries):
		status = self.default_entries.copy()
		status.update(entries)

		if self.has_entry(dsnumber):
			self.update_ds(dsnumber, status)
		else:
			self.add_ds(dsnumber, status)
		print(self.get_ds_info(dsnumber))