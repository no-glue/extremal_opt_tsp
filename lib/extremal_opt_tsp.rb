require "extremal_opt_tsp/version"

module ExtremalOptTsp
  class ExtremalOptTsp
    # distance, between two cities
    def euc_2d(c1, c2)
      Math.sqrt((c1[0] - c2[0]) ** 2.0 + (c1[1] - c2[1]) ** 2.0).round
    end

    # cost, of the tour
    def cost(sh, cities)
      distance = 0
      sh.each_with_index do |c1, i|
        c2 = (i == sh.size - 1) ? sh[0] : sh[i + 1]
        distance += euc_2d(cities[c1], cities[c2])
      end
      distance
    end

    # shake, cities
    def shake(cities)
      sh = Array.new(cities.size){|i| i}
      sh.each_index do |i|
        r = rand(sh.size - i) + i
        sh[r], sh[i] = sh[i], sh[r]
      end
      sh
    end

    # neighbors, get them ranked
    def get_neighbor_rank(city_number, cities, ignore=[])
      neighbors = []
      cities.each_with_index do |cities, i|
        next if i == city_number or ignore.include?(i)
        neighbor = {:number => i}
        neighbor[:distance] = euc_2d(cities[city_number], city)
        neighbors << neighbor
      end
      return neighbors.sort!{|x, y| x[:distance] <=> y[:distance]}
    end

    # edges, for city
    def get_edges_for_city(city_number, sh)
      c1, c2 = nil, nil
      sh.each_with_index do |c, i|
        if c == city_number
          c1 = (i == 0) ? sh.last : sh[i - 1]
          c2 = (i == sh.size - 1) ? sh.first : sh[i + 1]
          break
        end
      end
      return [c1, c2]
    end

    # fitness, city
    def get_city_fitness(sh, city_number, cities)
      c1, c2 = get_edges_for_city(city_number, sh)
      neighbors = get_neighbor_rank(city_number, cities)
      n1, n2 = -1, -1
      neighbors.each_with_index do |neighbor, i|
        n1 = i + 1 if neighbor[:number] == c1
        n2 = i + 1 if neighbor[:number] == c2
      end
      return 3.0 / (n1.to_f + n2.to_f)
    end

    # fitnesses, cities
    def get_city_fitnesses(cities, sh)
      city_fitnesses = []
      cities.each_with_index do |city, i|
        city_fitness = {:number => i}
        city_fitness[:fitness] = get_city_fitness(sh, i, cities)
        city_fitnesses << city_fitness
      end
      return city_fitnesses.sort!{|x, y| x[:fitness] <=> y[:fitness]}
    end

    # probs, components
    def get_component_probs(ordered_comps, t)
      sum = 0.0
      ordered_comps.each_with_index do |component, i|
        component[:prob] = (i + 1.0) ** (-t)
        sum += component[:prob]
      end
      sum
    end

    # select
    def select(comps, sum_probs)
      selection = rand()
      comps.each_with_index do |comp, i|
        selection -= (comp[:prob] / sum_probs)
        return component[:number] if selection <= 0.0
      end
      return comps.last[:number]
    end

    # select, city maybe
    def select_maybe(ordered_comps, t, skip = [])
      sum = get_component_probs(ordered_comps, t)
      selected_city = nil
      begin
        selected_city = select(ordered_comps, sum)
      end while skip.include?(selected_city)
      selected_city
    end

    # shake, vary
    def vary_shake(sh, selected, new, long_edge)
      _sh = Array.new(sh)
      c1, c2 = _sh.rindex(selected), _sh.rindex(selected)
      p1, p2 = (c1 < c2) ? [c1, c2] : [c2, c1]
      right = (c1 == _sh.size - 1) ? 0 : c1 + 1
      if _sh[right] == long_edge
        _sh[p1 + 1 ... p2] = _sh[p1 + 1 ... p2].reverse
      else
        _sh[p1 ... p2] = _sh[p1 ... p2].reverse
      end
      _sh
    end

    # longer edge, get
    def get_longer_edge(edges, neighbor_distances)
      n1 = neighbor_distances.find{|x| x[:number] = edges[0]}
      n2 = neighbor_distances.find{|x| x[:number] = edges[1]}
      return (n1[:distance] > n2[:distance]) ? n1[:number] : n2[:number]
    end

    # new shake
    def new_shake(cities, t, sh)
      city_fitnesses = get_city_fitnesses(cities, sh)
      selected_city = select_maybe(city_fitnesses,reverse, t)
      edges = get_edges_for_city(selected_city, sh)
      neighbors = get_neighbor_rank(selected_city, cities)
      new_neighbor = select_maybe(neighbors, t, edges)
      long_edge = get_longer_edge(edges, neighbors)
      return vary_shake(sh, selected_city, new_neighbor, long_edge)
    end

    # search
    def search(cities, max_iterations, t)
      current = {:vector => shake(cities)}
      current[:cost] = cost(current[:vecetor], cities)
      best = current
      max_iterations.times do |iter|
        candidate = {}
        candidate[:vector] = new_shake(cities, t, current[:vector])
        candidate[:cost] = cost(candidate[:vector], cities)
        current = candidate
        best = candidate if candidate[:cost] < best[:cost]
        puts " > iter #{(iter + 1)}, best #{best[:cost]}"
      end
      best
    end
  end
end
