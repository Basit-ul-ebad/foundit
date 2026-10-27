// Campus settings. One pilot campus; the data model supports more.
// Zones and neighbours are sample values until the real campus is confirmed.

const kCampusId = 'comsats-isb';
const kCampusName = 'COMSATS Islamabad (pilot, sample)';

const campusZones = [
  'Library',
  'Cafeteria',
  'Block A',
  'Block B',
  'Sports ground',
];

// Zone distance: same zone 1.0, neighbouring zone 0.6, same campus 0.3.
const zoneNeighbours = <String, List<String>>{
  'Library': ['Block A', 'Cafeteria'],
  'Cafeteria': ['Library', 'Block B'],
  'Block A': ['Library', 'Block B'],
  'Block B': ['Cafeteria', 'Block A', 'Sports ground'],
  'Sports ground': ['Block B'],
};

const categories = [
  'Bag',
  'Phone',
  'Wallet',
  'Keys',
  'Student card',
  'Charger',
  'Other',
];

// Related categories score 0.5 (for example a phone and its charger).
const relatedCategories = <String>{
  'Phone|Charger',
  'Charger|Phone',
  'Wallet|Student card',
  'Student card|Wallet',
};

const colourOptions = [
  'Black',
  'Blue',
  'Red',
  'Green',
  'White',
  'Grey',
  'Brown',
  'Other',
];

const ageBands = ['13-17', '18-24', '25+'];

const deskInfo = 'Campus desk, Admin block, 9:00 am to 4:00 pm (sample)';
