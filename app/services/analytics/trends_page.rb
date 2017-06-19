module Analytics
  class TrendsPage
    TIME_QUERIES = {
      'changes_in_the_last_week' => 1.week.ago,
      'changes_in_the_last_two_weeks' => 2.weeks.ago,
      'changes_in_the_last_month' => 1.month.ago
    }.freeze

    DEFAULT_QUERY = 'changes_in_the_last_two_weeks'.freeze

    attr_reader :time_span_query

    def initialize(time_span_query)
      @time_span_query = time_span_query
    end

    def self.queries
      TIME_QUERIES.keys
    end

    def queries
      TIME_QUERIES.keys
    end

    def time_query
      TIME_QUERIES[time_span_query || DEFAULT_QUERY]
    end

    def change_over_time
      grouped_events = TaggingEvent
        .since(time_query)
        .order(tagged_at: :asc)
        .group_by(&:tagged_on)

      guidance_series = {}
      other_series = {}

      days = (time_query.to_date..Date.today).to_a

      days.each do |day|
        guidance_series[day] = 0
        other_series[day] = 0

        grouped_events.fetch(day, []).each do |event|
          if event.guidance?
            guidance_series[day] += event.change
          else
            other_series[day] += event.change
          end
        end
      end

      [
        { name: "Guidance", data: guidance_series },
        { name: "Other content", data: other_series }
      ]
    end

    def taxons
      taxons = TaggingEvent
        .group(:taxon_title, :taxon_content_id)
        .since(time_query)
        .order(taxon_title: :asc)
        .count
        .map { |t| { title: t[0][0], id: t[0][1] } }

      recent_changes = TaggingEvent
        .since(time_query)
        .group(:taxon_content_id, :taggable_navigation_document_supertype)
        .sum(:change)

      taxons.map do |taxon|
        {
          title: taxon[:title],
          id: taxon[:id],
          guidance_change: recent_changes[[taxon[:id], 'guidance']] || 0,
          other_change: recent_changes[[taxon[:id], 'other']] || 0
        }
      end
    end
  end
end
