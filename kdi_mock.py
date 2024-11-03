"""
Name: Zadatak 2
Author: Boris Tomka
Created: 2024-11-03
Modified: 2024-11-03
Version: 1.0
Copyright: (c) KnowIt d.o.o. 2024
"""
import os
import random
import string
import datetime
import zipfile
import json
import argparse

def random_number_string(length=13):
    """Generate a random numeric string of fixed length."""
    return ''.join(random.choices(string.digits, k=length))

def create_zip_file(num_files, date_dir):
    """Create a zip file containing a single file."""
    partije = list()

    for _ in range(num_files):
        file_base_num = random_number_string(13)
        file_type = ['json', 'pdf', 'txt']
        partije.append(file_base_num)
        
        for each_type in file_type:
            zip_filename = f"{file_base_num}.{each_type}.zip"
            zip_path = os.path.join(date_dir, zip_filename)

            with zipfile.ZipFile(zip_path, 'w') as zipf:
                inner_filename = f"{file_base_num}.{each_type}"
                zipf.writestr(inner_filename, '')
            print(f"-----Created partija file: {zip_path}")

    return partije

def generate_partije_json(id_number, partije):
    """Generate the {ID}_partije.json file content."""
    data = {
        id_number:[partija for partija in partije if random.random() < 0.5]
    }
    return json.dumps(data)

def insert_random_partije_json(args, org_partije):
    """In existing *_partije.json, randomly add partije from other orgIDs"""
    base_dir = args.base_dir
    for num_org in range(args.num_orgs):
        random_id = random.sample(list(org_partije.keys()), 1)

        for id_num, partije in org_partije.items():
            if id_num != random_id[0]:
                if random.random() < args.per_acc:
                    id_dir1 = os.path.join(base_dir, random_id[0], f"{random_id[0]}_partije.json")
                    id_dir2 = os.path.join(base_dir, id_num, f"{id_num}_partije.json")
                    if os.path.exists(id_dir1) and os.path.exists(id_dir2):
                        with open(id_dir1, 'r') as file1:
                            try:
                                data1 = json.load(file1)
                            except json.JSONDecodeError:
                                print(f"Error decoding JSON from {id_dir1}. Initializing empty dict.")
                                data1 = {}
                        with open(id_dir2, 'r') as file2:
                            try:
                                data2 = json.load(file2)
                            except json.JSONDecodeError:
                                print(f"Error decoding JSON from {id_dir2}. Initializing empty dict.")
                                data2 = {}
                        
                        merged_data = {**data1, **data2}
                        with open(id_dir1, 'w') as outfile:
                            json.dump(merged_data, outfile)
                        print(f"Organisation ID:{random_id[0]} has access to Org.ID:{id_num}.")
                    else:
                        missing_files = []
                        if not os.path.exists(id_dir1):
                            missing_files.append(id_dir1)
                        if not os.path.exists(id_dir2):
                            missing_files.append(id_dir2)
                        print(f"File(s) do not exist: {', '.join(missing_files)}")

def random_date(start, end):
    """Generate a random date between start and end. Default should be two months"""
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + datetime.timedelta(days=random_days)

def create_mock_structure(args):
    """Creates folder and files structure structure based on parameters"""
    org_partije = {}

    base_dir = args.base_dir
    os.makedirs(base_dir, exist_ok=True)
    print(f"Created base directory: {base_dir}")

    ids = set()
    while len(ids) < args.num_ids:
        id_num = ''.join(random.choices(string.digits, k=args.id_length))
        ids.add(id_num)
    ids = list(ids)

    for id_num in ids:
        partije = []

        id_dir = os.path.join(base_dir, id_num)
        os.makedirs(id_dir, exist_ok=True)
        print(f"-Created ID directory: {id_dir}")

        num_dates = random.randint(args.min_dates, args.max_dates)
        start_date = datetime.datetime.strptime(args.start_date, "%Y-%m-%d")
        end_date = datetime.datetime.strptime(args.end_date, "%Y-%m-%d")
        date_dirs = set()
        while len(date_dirs) < num_dates:
            date = random_date(start_date, end_date)
            date_str = date.strftime("%Y-%m-%d")
            date_dirs.add(date_str)
        date_dirs = sorted(list(date_dirs), reverse=True)

        for date_str in date_dirs:
            date_dir = os.path.join(id_dir, date_str)
            os.makedirs(date_dir, exist_ok=True)
            print(f"---Created date directory: {date_dir}")

            num_files = random.randint(args.min_partija, args.max_partija)
            partije.extend(create_zip_file(num_files, date_dir))

            if random.random() < 0.3:
                image_path = os.path.join(date_dir, "image.png")
                with open(image_path, 'wb') as imgf:
                    imgf.write(os.urandom(1024))
                print(f"-----Created image file: {image_path}")

            if random.random() < 0.2:
                notes_path = os.path.join(date_dir, "notes.txt")
                with open(notes_path, 'w') as notef:
                    notef.write("Zadatak 2")
                print(f"-----Created txt file: {notes_path}")

        partije_content = generate_partije_json(id_num, partije)
        partije_path = os.path.join(id_dir, f"{id_num}_partije.json")
        with open(partije_path, 'w') as partf:
            partf.write(partije_content)
        print(f"---Created partije file: {partije_path}")

        org_partije[id_num] = partije

    return org_partije


def main():
    parser = argparse.ArgumentParser(description="Generate mock data directory structure.")
    parser.add_argument('--base_dir', type=str, default='izvodi', help='Base directory to create. [Default (str): izvodi]')
    parser.add_argument('--num_ids', type=int, default=5, help='Number of ID directories to create. [Default (int): 5]')
    parser.add_argument('--id_length', type=int, default=5, help='Length of the numeric ID. [Default (int): 5]')
    parser.add_argument('--start_date', type=str, default='2024-09-10', help='Start date for date directories (YYYY-MM-DD). [Default (str): 2024-09-10]')
    parser.add_argument('--end_date', type=str, default='2024-11-10', help='End date for date directories (YYYY-MM-DD). [Default (str): 2024-11-10]')
    parser.add_argument('--min_dates', type=int, default=2, help='Minimum number of date directories per ID. [Default (int): 2]')
    parser.add_argument('--max_dates', type=int, default=15, help='Maximum number of date directories per ID. [Default (int): 15]')
    parser.add_argument('--min_partija', type=int, default=2, help='Minimum number of partije per date directory. [Default (int): 2]')
    parser.add_argument('--max_partija', type=int, default=6, help='Maximum number of partije per date directory. [Default (int): 6]')
    parser.add_argument('--num_orgs', type=int, default=2, help='The number of possible organizations that will have access to others depending on the percentage of probability. [Default (int): 2]')
    parser.add_argument('--per_acc', type=float, default=0.5, help='Percentage of merge probability with other organisations (0.5 = 50 percent). [Default (float): 0.5]')

    args = parser.parse_args()
    org_partije = create_mock_structure(args)
    insert_random_partije_json(args, org_partije)

    print("Mock data generation complete.")

if __name__ == "__main__":
    main()
