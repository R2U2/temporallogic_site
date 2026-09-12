#include <string>
#include <iostream>

/*Includes for Variable Ordering capabilities*/
#include "typedefs.h" /*rgl2: mcs_start_t*/
#include "graph.h"    /*rgl2: connect_graph() and alloc_graph()*/
#include "graphops.h" /*rgl2: mcs_graph()*/

using std::ostream;
using std::string;
using std::endl;

#ifndef _KItem_h_
#define _KItem_h_

class KItem {
 public:
  // Constructor
  KItem();

  // Parameterized Constructor
  KItem(string myName, int myInfo, int myOutDegree);

  // Partial Parameterized Constructor
  KItem(string myName);

  // Copy constructor
  KItem(const KItem &copyin);

  // Destructor
  ~KItem();

  void setAll(string myName, int myInfo, int myOutDegree);
  void setName(string myName);       // set the name of the KItem
  string getName();                  // get the name of the KItem
  void setInfo(int myInfo);          // set the info of the KItem
  int getInfo();                     // get the info of the KItem
  void setOutDegree(int outDegree);  // set the out degree of the KItem
  int getOutDegree();                // get the out degree of the KItem

  // For list
  KItem &operator=(const KItem &rhs);
  int operator==(const KItem &rhs) const;
  int operator<(const KItem &rhs) const;

  // Diagnostics
  void print(ostream &out);

 private:
  string name;
  int info;
  int outDegree;

}; //end KItem

#endif
