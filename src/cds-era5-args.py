import cdsapi
import argparse
import sys
from pathlib import Path
from multiurl import download

text = 'Download cds data with command date selections.'

parser = argparse.ArgumentParser(description=text)
parser.add_argument("-V", "--version", help="show program version", action="store_true")
parser.add_argument("-y", "--years", nargs='+', help="set download years (required), e.g. -y 2020 2021", required=True)
parser.add_argument("-m", "--months", nargs='+', help="set download months (required), e.g. -m 01 02 03", required=True)
parser.add_argument("-d", "--days", nargs='+', help="set download days, e.g. -d 10 11 12; if not set, will default to all days (01 - 31)")
parser.add_argument("-c", "--climvars", nargs='+', help="set climate variable(s) to download, currently supporting: 'temperature', 'spec_humid', 'rel_humid', 'uv', 'precipitation', e.g. -c temperature rel_humid", required=True)
parser.add_argument("-f", "--folder", help="output to folder named according to parameters", action="store_true")

args = parser.parse_args()

if args.version:
    print("This is version 0.4 of the CDS download script")

# Construct days list if not provided
if args.days:
    dldays = args.days
else:
    dldays = ['01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
            '13', '14', '15',
            '16', '17', '18',
            '19', '20', '21',
            '22', '23', '24',
            '25', '26', '27',
            '28', '29', '30',
            '31']

print("Downloading climate variable(s) %s" % args.climvars)
print("Download for year(s) %s" % args.years)
print("Download for month(s) %s" % args.months)
print("Download for day(s) %s" % dldays)

outfolder = "data"

# Construct output folder if required
if args.folder:
    outfolder = "data/{}_{}".format("-".join(args.years), "-".join(args.months))
    print("Output folder {}".format(outfolder))
    # Make sure folder exists, and create if not
    Path(outfolder).mkdir(parents=True, exist_ok=True)

# Force line break for nice formatting
print()

# Allow for alternative names
alt_names = {
    "temp": "temperature",
    "spechumid": "spec_humid",
    "relhumid": "rel_humid",
    "precip": "precipitation",
}

climvars = [alt_names.get(x, x) for x in args.climvars]

# Data store for supported rasters. When you add new ones from era5 you may just need to add a line here
rasterlookup = {
    "temperature": {"name": "reanalysis-era5-pressure-levels", "variable": "temperature", "filename": "cds-temp.grib"},
    "spec_humid": {"name": "reanalysis-era5-pressure-levels", "variable": "specific_humidity", "filename": "cds-spechumid.grib"},
    "rel_humid": {"name": "reanalysis-era5-pressure-levels", "variable": "relative_humidity", "filename": "cds-relhumid.grib"},
    "uv": {"name": "reanalysis-era5-single-levels", "variable": "downward_uv_radiation_at_the_surface", "filename": "cds-uv.grib"},
    "precipitation": {"name": "reanalysis-era5-single-levels", "variable": "total_precipitation", "filename": "cds-precip.grib"}
}

notified = False

if not (args.years and args.months and dldays):
    # Should never trigger as these required arguments are now enforced by argparse
    print("Error: You didn't specify one of the required arguments - see --help for more details.")
    sys.exit(1)

# Run download code depending on which climate variable is selected
for climvar in climvars:
    # Try to get the data for the provided climatic variable
    try:
        climvardata = rasterlookup[climvar]
    except KeyError:
        # If not present, notify and skip
        print("\nERROR: '{}' is not a valid variable!".format(climvar))
        if not notified:
            # Only show once
            print("\nValid options are:\n  - {}".format("\n  - ".join(list(rasterlookup.keys()))))
            notified = True
        continue

    print("Retrieving {}...".format(climvar))

    # do all the CDS stuff
    c = cdsapi.Client()

    c.retrieve(
        climvardata["name"],
        {
            'product_type': 'reanalysis',
            'variable': climvardata["variable"],
            'pressure_level': '1000',
            'year': args.years,
            'month': args.months,
            'day': dldays,
            'time': [
                '00:00', '01:00', '02:00',
                '03:00', '04:00', '05:00',
                '06:00', '07:00', '08:00',
                '09:00', '10:00', '11:00',
                '12:00', '13:00', '14:00',
                '15:00', '16:00', '17:00',
                '18:00', '19:00', '20:00',
                '21:00', '22:00', '23:00',
            ],
            'format': 'grib',
        },
        '{}/{}'.format(outfolder, climvardata["filename"]))

print("\nDownload complete!")
