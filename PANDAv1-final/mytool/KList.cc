#include <string>
#include <math.h>
#include "KList.h"
#include "KItem.h"

using std::ostream;
using std::string;
using std::list;


// Constructor
KList::KList() {
  listname = "";
  items.clear();
  uniqueId = 0;
} //end constructor

// Parameterized constructor
KList::KList(string myName, list<KItem> myItems) {
  listname = myName;
  items = myItems;  
  cacheDirty = 1;
  uniqueId = 0;
} //end parameterized constructor

// Copy constructor
KList::KList(const KList &copyin) {
  listname = copyin.listname;
  items = copyin.items;
  cacheDirty = 1;
  uniqueId = 0;
} //end copy constructor

// Destructor
KList::~KList() {
  items.clear();
} //end destructor

// clear the list
void KList::clear() {
  items.clear();
  cacheDirty = 1;
  uniqueId = 0;
} //end clear

// set all the parameters
void KList::setAll(string myName, list<KItem> myItems) {
  listname = myName;
  items = myItems;
  cacheDirty = 1;
} //end setAll

// set the name of the list
void KList::setName(string myName) {
  listname = myName;
} //end setName

// get the name of the list
string KList::getName() {
  return(listname);
} //end getName

// return the size
int KList::size() {
    return(items.size());
} //end size

// add/replace an item
int KList::addItem(KItem k) {
  int idx;
  if (!query(k)) { 
    idx = uniqueId;
    uniqueId++;
    k.setInfo(idx);
    items.remove(k);
    items.push_back(k);
    items.sort();
    cacheDirty = 1;	
    /*DEBUG: fprintf(stderr, "Adding item %s as var #%d -- %d\n", k.getName().c_str(), idx, (int)this);*/
  } //end if 
  else { // already there
    KItem val = find(k);
    idx = val.getInfo();
  } //end else
  return(idx);
} //end addItem

// save an item
int KList::saveItem(KItem k) {
  int result = 0;
  if (query(k)) { 
    items.remove(k);
    items.push_back(k);
    items.sort();
    cacheDirty = 1;	
    result = 1;
  } //end if
  else { // already there
    result = 0;
  } //end else
  return(result);
} //end saveItem

// remove an item from the list
void KList::removeItem(KItem k) {
  items.remove(k);
  cacheDirty = 1;
} //end removeItem

// get items
list<KItem> KList::getItems() {
  list<KItem> dummy = items;
  return(dummy);
} //end getItems

// retrieve an item
KItem KList::find(KItem k) {
  list<KItem> dummy = items;
  int success = 0;
  KItem val;  

  if (!cacheDirty) { // We have a cached result which might work
    if (k == cached) { // searches match!
      val = cachedResult;
      success = 1;
    } //end if
  } //end if

  // Loop until found
  while((dummy.empty() != 1) && (success == 0)) {
    val = dummy.front();
    dummy.pop_front();
    if (val == k) { // found it!
      success = 1;
    } //end if
  } //end while
  if (success == 0) { // return error
    val.setName("ERR-UNFOUND-KITEM");
  } //end if

  cacheDirty = 0;
  cachedResult = val;
  cached = k;

  return(val);
} //end find

// retrieve an item
string KList::findName(int myIdx) {
  list<KItem> dummy = items;
  int success = 0;
  string retVal;
  KItem val;

  // Loop until found
  while((dummy.empty() != 1) && (success == 0)) {
    val = dummy.front();
    dummy.pop_front();
    if (val.getInfo() == myIdx) { // found it!
      success = 1;
    } //end if
  } //end while
  if (success == 0) { // return error
    val.setName("ERR-UNFOUND-IDX");
  } //end if

  retVal = val.getName();

  return(retVal);
} //end findName

// retrieve an item
KItem KList::findItemByNumber(int myIdx) {
  list<KItem> dummy = items;
  int success = 0;
  KItem val;

  // Loop until found
  while((dummy.empty() != 1) && (success == 0)) {
    val = dummy.front();
    dummy.pop_front();
    if (val.getInfo() == myIdx) { // found it!
      success = 1;
    } //end if
  } //end while
  if (success == 0) { // return error
    val.setName("ERR-UNFOUND-IDX");
  } //end if

  return(val);
} //end findItemByNumber

// query if item exists
int KList::query(KItem k) {
  KItem q;
  KItem dummy;
  dummy.setName("ERR-UNFOUND-KITEM");  

  if (!cacheDirty && (cached == k)) { // cached result which works
    q = cachedResult;
  } //end if
  else { // no cached result which works
    q = find(k);
  } //end else

  cacheDirty = 0;
  cachedResult = q;
  cached = k;

  if (q == dummy) {
    return(0);
  } //end if
  return(1);
} //end query

//print
void KList::print(ostream &out) {
  out << "LIST " << listname << endl << endl;
  
  list<KItem> dummy = items;
  dummy.sort();

  // while not empty
  while (dummy.empty() != 1) {
    KItem k = dummy.front();
    dummy.pop_front();
    out << "\t" << k.getName() << " " << k.getInfo() << endl;
  } //end while
} //end print
