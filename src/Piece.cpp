#include "Piece.h"
#include"ExternFunctions.h"

#include <math.h>
#include <stdlib.h>
#include<iostream>
#include<typeinfo>

#include <fstream> ///write in a file
#include<vector>

Piece::Piece(){m_info = Track(); m_interval = Interval(); m_cost = Cost(); nxt = NULL;}
Piece::Piece(Track const& info, Interval const& inter, Cost const& cost)
{
  m_info = info;
  m_interval = inter;
  m_cost = cost;
  nxt = NULL;
}

Piece::Piece(const Piece* piece)
{
  m_info = piece -> m_info;
  m_interval = piece -> m_interval;
  m_cost = piece -> m_cost;
  nxt = NULL;
}


//####### destructor #######////####### destructor #######////####### destructor #######//
//####### destructor #######////####### destructor #######////####### destructor #######//

Piece::~Piece()
{
  delete(nxt);
  nxt = NULL;
}



//####### copy #######////####### copy #######////####### copy #######//
//####### copy #######////####### copy #######////####### copy #######//

Piece* Piece::copy()
{
  return(new Piece(this));
}



//####### getMin #######////####### getMin #######////####### getMin #######//
//####### getMin #######////####### getMin #######////####### getMin #######//

double Piece::getMin()
{
  return(cost_minInterval(m_cost, m_interval));
}



//####### addCostAndPenalty #######////####### addCostAndPenalty #######////####### addCostAndPenalty #######//
//####### addCostAndPenalty #######////####### addCostAndPenalty #######////####### addCostAndPenalty #######//

void Piece::addCostAndPenalty(Cost const& cost, double penalty)
{
  m_cost.m_A = m_cost.m_A + cost.m_A;
  m_cost.m_B = m_cost.m_B + cost.m_B;
  m_cost.constant = m_cost.constant + cost.constant + penalty;
}



//####### intervalMinLess #######////####### intervalMinLess #######////####### intervalMinLess #######//
//####### intervalMinLess #######////####### intervalMinLess #######////####### intervalMinLess #######//


Interval Piece::intervalMinLess(double leftBound, double currentValue, bool constPiece)
{
  Interval response = Interval(); /// Interval = (INFINITY, INFINITY)
  double mini = cost_min(m_cost);


  if(currentValue > mini) /// otherwise currentValue constant doesn't intersect Piece cost
  {
    double argmini = cost_argmin(m_cost);
    if(leftBound < argmini) /// otherwise currentValue constant doesn't intersect Piece cost
    {
      if(constPiece == true)
      {
        double* coeff = new double[3];
        coeff[0] = m_cost.m_A;
        coeff[1] = m_cost.m_B;
        coeff[2] = m_cost.constant;
        Cost costInter = Cost(coeff);
        response = cost_intervalInterRoots(costInter, currentValue);
        response.setb(argmini);
        delete(coeff);
      }
      else /// i.e. point_eval(leftBound) == current_min : continuity condition
      {
        response.seta(leftBound);
        response.setb(argmini);
      }
    }
  }

  return(response);
}



//####### pastePiece #######// //####### pastePiece #######// //####### pastePiece #######//
//####### pastePiece #######// //####### pastePiece #######// //####### pastePiece #######//


Piece* Piece::pastePiece(const Piece* Q, Interval const& decrInter, Track const& newTrack)
{
  Piece* BUILD = this;

  /// decreasingInterval = (a,b)
  /// Q -> m_interval = (m_a,m_b)

  if(decrInter.isEmpty())
  {
    BUILD -> m_interval.setb(Q -> m_interval.getb());
  }
  else
  {
    BUILD -> m_interval.setb(decrInter.geta());    ///if a > m_a, no change otherwise

    ///ADD of the PIECE Q (troncated)
    if(BUILD -> m_interval.isEmpty()) ///if BUILD empty
    {
      BUILD -> m_interval.setb(decrInter.getb());
      BUILD -> m_cost = Q -> m_cost;
      BUILD -> m_info.setTrack(newTrack);
    }
    else
    {
      Piece* NewQ = new Piece(newTrack, decrInter, Q -> m_cost);
      BUILD -> nxt = NewQ;
      BUILD = NewQ;
    }

    if(!((Q -> nxt == NULL) && (decrInter.getb() == Q -> m_interval.getb())))
    {
      double outputValue = cost_eval(Q -> m_cost, decrInter.getb());
      Piece* PieceOut = new Piece(newTrack, Interval(decrInter.getb(), Q -> m_interval.getb()), Cost());
      addmyConstant(PieceOut -> m_cost, outputValue);
      BUILD -> nxt = PieceOut;
      BUILD = PieceOut;
    }

  }

  return(BUILD);
}


/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////


void Piece::show()
{
  Piece* tmp = this;
  if(tmp == NULL){std::cout << "#NULL EMPTY POINTER# "<< std::endl;}
  else
  {
    std::cout << tmp;
    std::cout << " #LABEL# "<< tmp -> m_info.getLabel() << " #STATE# " <<  tmp -> m_info.getState() << " POSITION " << tmp -> m_info.getPosition() << " ";
    std::cout << "#INTERVAL# "<< tmp -> m_interval.geta() << " -- " << tmp -> m_interval.getb() << " ";
    showCost(tmp ->m_cost);
    std::cout << std::endl;
  }
}



