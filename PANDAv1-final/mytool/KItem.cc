#include <stdio.h>
#include <string>
#include "KItem.h"
#include "KList.h"

using std::ostream;
using std::string;

// Constructor
KItem::KItem() {
  name = "";
  info = -1;
  outDegree = 0;
} //end constructor

// Parameterized Constructor
KItem::KItem(string myName, int myInfo, int myOutDegree) {
  name = myName;
  info = myInfo;
  outDegree = myOutDegree;
} //end parameterized constructor

// Parameterized Constructor
KItem::KItem(string myName) {
  name = myName;
  info = -1;
  outDegree = 0;
} //end parameterized constructor

// Copy constructor
KItem::KItem(const KItem &copyin) {
  name = copyin.name;
  info = copyin.info;
  outDegree = copyin.outDegree;
} //end copy constructor

// Destructor
KItem::~KItem() {
  // Empty
} //end destructor

// set everything
void KItem::setAll(string myName, int myInfo, int myOutDegree) {
  name = myName;
  info = myInfo;
  outDegree = myOutDegree;
} //end setAll

// set the name of the KItem
void KItem::setName(string myName) {
  name = myName;
} //end setName

// get the name of the KItem
string KItem::getName() {
  return(name);
} //end getName

// set the info of the KItem
void KItem::setInfo(int myInfo) {
  info = myInfo;
} //end setInfo

// get the info of the KItem
int KItem::getInfo() {
  return(info);
} //end getInfo

// set the out degree of the KItem (if it's in a graph)
void KItem::setOutDegree(int myOutDegree) {
  outDegree = myOutDegree;
} //end setOutDegree

// get the out degree of the KItem (if it's in a graph)
int KItem::getOutDegree() {
  return(outDegree);
} //end getOutDegree




//*******************************************************************
// For lists
//*******************************************************************

// =
KItem& KItem::operator=(const KItem &rhs) {
  this->name = rhs.name;
  this->info = rhs.info;
  this->outDegree = rhs.outDegree;
  return *this; /*2022 fix; thanks g++ compiler*/
} //end operator=

// ==
int KItem::operator==(const KItem &rhs) const {
  if (this->name == rhs.name) return 1;
  return 0;
} //end operator==

// <
int KItem::operator<(const KItem &rhs) const {
  if (this->name < rhs.name) return 1;
  return 0;
} //end operator<

// print
void KItem::print(ostream &out) {
  out << name << "\t" << info << endl;
  return;
} //end print
