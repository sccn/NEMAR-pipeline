import os
from pathlib import Path
from datetime import date, datetime
import json

def write_bad_participant_message(bad_parcipants):
    for ds in bad_participants:
        print(ds)
        nemarjson_file = f"/expanse/projects/nemar/openneuro/processed/{ds}/code/nemar.json"
        if os.path.exists(nemarjson_file):
            with open(nemarjson_file) as f:
                nemar_json = json.load(f)
                nemar_json['warning'] = "Participant information (participants.tsv) missing or ill-formatted"
                print(nemar_json)
                with open(nemarjson_file, 'w') as out:
                    json.dump(nemar_json, out)

if __name__ == "__main__":
    nemar_path = '/expanse/projects/nemar/openneuro/processed'
    processed_ds = {'ds001785','ds001787','ds001810','ds001849','ds001971','ds002034','ds002094','ds002158','ds002218','ds002680','ds002691','ds002718','ds002720','ds002721','ds002722','ds002723','ds002724','ds002725','ds002778','ds002814','ds002893','ds003039','ds003061','ds003190','ds003194','ds003195','ds003343','ds003458','ds003474','ds003478','ds003506','ds003516','ds003517','ds003518','ds003519','ds003522','ds003523','ds003570','ds003574','ds003620','ds003626','ds003638','ds003645','ds003655','ds003670','ds003690','ds003702','ds003710','ds003739','ds003751','ds003753','ds003768','ds003774','ds003800','ds003801','ds003822','ds003825','ds003838','ds003885','ds003887','ds003944','ds004010','ds004015','ds004018','ds004019','ds004022','ds004033','ds004040','ds004043','ds004075','ds004105','ds004117','ds004121','ds004122','ds004147','ds004148','ds004151','ds004152','ds004196','ds004200','ds004252','ds004262','ds004264','ds004295','ds004315','ds004317','ds004324','ds004346','ds004347','ds004350','ds004357','ds004367','ds004369','ds004381','ds004457','ds004502','ds004504','ds004505','ds004515','ds004532','ds004572','ds004574','ds004577','ds004579','ds004580','ds004584','ds004588','ds004595','ds004657','ds004660','ds004752','ds004840','ds005170'}
    print(len(processed_ds))
    to_process = set()
    for ds in processed_ds:
        histogram_file = Path(nemar_path) / ds / 'code' / f"{ds}_histogram.svg"
        if not os.path.exists(histogram_file):
            to_process.add(ds)
        else:
            modified_date = datetime.fromtimestamp(os.path.getmtime(histogram_file)).date()
            if modified_date < date.today(): # Sep 20, 2024
                to_process.add(ds)

    bad_participants = {'ds004588', 'ds004577', 'ds004660', 'ds004121', 'ds004105', 'ds004324', 'ds003195', 'ds004043', 'ds003710', 'ds003458', 'ds004040', 'ds002094', 'ds003478', 'ds003190', 'ds001849', 'ds003774', 'ds003768', 'ds004122', 'ds004347', 'ds001971', 'ds003474', 'ds004295', 'ds003194', 'ds004408', 'ds002218', 'ds003626', 'ds002680', 'ds003522', 'ds003523'} 
    print('num bad participants', len(bad_participants))
    other_issues = {'ds004657', 'ds004572', 'ds004577', 'ds004033', 'ds003838', 'ds004075', 'ds004660', 'ds004022', 'ds003039', 'ds003702', 'ds004019', 'ds004588', 'ds004579', 'ds004367', 'ds003825', 'ds004346', 'ds004252', 'ds004350', 'ds003944', 'ds004502', 'ds004532', 'ds002722', 'ds002034'}
    print('num other issues', len(other_issues))
    # to_process = to_process-bad_participants-other_issues
    # to_process = sorted(to_process, reverse=True)
    # print('num to process', len(to_process))
    # print(to_process)
    bad_datasets = bad_participants.union(other_issues).union(to_process)
    print('total currently bad datasets', len(bad_datasets))

    # to_process = ['ds004347', 'ds004324', 'ds004295', 'ds004151', 'ds004122', 'ds004121', 'ds004105', 'ds004043', 'ds004040', 'ds003774', 'ds003768', 'ds003710', 'ds003626', 'ds003523', 'ds003522', 'ds003478', 'ds003474', 'ds003458', 'ds003195', 'ds003194', 'ds002722', 'ds002680', 'ds002218', 'ds002094', 'ds002034', 'ds001971', 'ds001849']

