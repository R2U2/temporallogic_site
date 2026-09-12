#include <string>
#include <iostream>
#include <list>

#ifndef __KList_h_
#define __KList_h_
#include "KItem.h"

using std::ostream;
using std::string;
using std::list;

class KList {
 public:
  // Constructor
  KList();  

  // Parameterized constructor
  KList(string myName, list<KItem> myItems);

  // Copy constructor
  KList(const KList &copyin);

  // Destructor
  ~KList();

  void clear();
  void setAll(string myName, list<KItem> myItems);
  void setName(string myName);  // set the name of the list
  string getName();             // get the name of the list
  int addItem(KItem k);         // add/replace an item
  int saveItem(KItem k);        // save an item
  void removeItem(KItem k);     // remove an item from the list
  list<KItem> getItems();       // get items
  KItem find(KItem k);          // retrieve an item
  string findName(int idx);     // retrieve an item
  KItem findItemByNumber(int myIdx); // retrieve an item
  int query(KItem k);           // query if item exists
  int size();                   // return size of the list

  // For diagnostics
  void print(ostream &out);

 private:
  string listname;
  list<KItem> items;

  int cacheDirty;
  KItem cached;
  KItem cachedResult;
  int uniqueId;

}; //end KList

#endif
