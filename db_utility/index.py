from models.Client import Client
from models.Problems import Problems
from models.Architectures import Architectures
from models.Instruments import Instruments
from models.Orbits import Orbits
from models.Attributes import Attributes
from models.Requirements import Requirements


from models.stakeholders import index_group_stakeholders

from models.Client import index_walker_mission_analysis


default_group_name = 'seakers (default)'


def main():
    client = Client()

    # DROP / CREATE TABLES
    client.initialize()

    # 1. Index default group
    client.goc_group(default_group_name)

    # 2. Index problems from excel files
    Problems(client).index()

    # 3. For each problem, index any existing walker constellation analysis
    index_walker_mission_analysis(client)

    # 4. For each problem, index existing evaluated architectures
    Architectures(client).index()

    # 5. For the default group, index all instruments found across all problems
    insts = Instruments(client)
    insts.index()

    # 6. For the default group, index all orbits found across all problems
    orbs = Orbits(client)
    orbs.index()

    # 7. For the default group, index attributes across all problems
    attr = Attributes(client)
    attr.index()
    attr.index_fuzzy_rules()

    # 8. For each problem, index orbit and instrument attributes
    orbs.index_local()
    insts.index_local()

    # 9. For each problem, index stakeholders
    data = {}
    index_group_stakeholders(client.get_session(), data, client)

    # 10. For each problem, index requirements
    Requirements(client).index()


if __name__ == "__main__":
    main()