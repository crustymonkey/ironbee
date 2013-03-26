/*****************************************************************************
 * Licensed to Qualys, Inc. (QUALYS) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * QUALYS licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ****************************************************************************/

/**
 * @file
 * @brief Predicate --- Standard Nodes
 *
 * @author Christopher Alfeld <calfeld@qualys.com>
 */

#ifndef __PREDICATE__STANDARD__
#define __PREDICATE__STANDARD__

#include "dag.hpp"
#include "validate.hpp"

#include "call_factory.hpp"

namespace IronBee {
namespace Predicate {
namespace Standard {

/**
 * Falsy value, null.
 **/
class False :
    public Validate::Call<False>,
    public Validate::NChildren<0>
{
public:
    //! See Call::name()
    virtual std::string name() const;

   /**
    * See Node::transform().
    *
    * Will replace self with Null.
    **/
   virtual bool transform(
       NodeReporter        reporter,
       MergeGraph&        merge_graph,
       const CallFactory& call_factory
   );

protected:
    //! See Node::calculate()
    virtual Value calculate(Context);
};

/**
 * Truthy value, ''.
 **/
class True :
    public Validate::Call<True>,
    public Validate::NChildren<0>
{
public:
    //! See Call::name()
    virtual std::string name() const;

   /**
    * See Node::transform().
    *
    * Will replace self with ''.
    **/
   virtual bool transform(
       NodeReporter        reporter,
       MergeGraph&        merge_graph,
       const CallFactory& call_factory
   );

protected:
    //! See Node::calculate()
    virtual Value calculate(Context);
};

/**
 * Base class for calls that want children in canonical order.
 **/
class AbelianCall :
    public Validate::Call<AbelianCall>,
    public Validate::NOrMoreChildren<2>
{
public:
    //! Constructor.
    AbelianCall();

    // The three routines below simply mark this node as unordered.
    //! See Node::add_child().
    virtual void add_child(const node_p& child);
    //! See Node::replace_child().
    virtual void replace_child(const node_p& child, const node_p& with);

    /**
     * See Node::transform().
     *
     * Will order children canonically.
     **/
    virtual bool transform(
        NodeReporter       reporter,
        MergeGraph&        merge_graph,
        const CallFactory& call_factory
    );

private:
    typedef Validate::Call<AbelianCall> parent_t;
    bool m_ordered;
};

/**
 * True iff any children are truthy.
 **/
class Or :
    public AbelianCall
{
public:
    //! See Call::name()
    virtual std::string name() const;

   /**
    * See Node::transform().
    *
    * Will replace self with '' if any child is true.
    * Will order children canonically.
    **/
   virtual bool transform(
       NodeReporter        reporter,
       MergeGraph&        merge_graph,
       const CallFactory& call_factory
   );

protected:
    virtual Value calculate(Context context);
};

/**
 * True iff all children are truthy.
 **/
class And :
    public AbelianCall
{
public:
    //! See Call::name()
    virtual std::string name() const;

   /**
    * See Node::transform().
    *
    * Will replace self with null if any child is false.
    * Will order children canonically.
    **/
   virtual bool transform(
       NodeReporter        reporter,
       MergeGraph&        merge_graph,
       const CallFactory& call_factory
   );
protected:
    virtual Value calculate(Context context);
};

/**
 * True iff child is falsy.
 **/
class Not :
    public Validate::Call<Not>,
    public Validate::NChildren<1>
{
public:
    //! See Call::name()
    virtual std::string name() const;

    /**
     * See Node::transform().
     *
     * Will replace self with a true or false value if child is a literal.
     **/
    virtual bool transform(
        NodeReporter       reporter,
        MergeGraph&        merge_graph,
        const CallFactory& call_factory
    );

protected:
    virtual Value calculate(Context context);
};

/**
 * Load all standard calls into a CallFactory.
 *
 * @param [in] to CallFactory to load into.
 **/
void load(CallFactory& to);

} // Standard
} // Predicate
} // IronBee

#endif
