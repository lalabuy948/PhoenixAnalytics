"use client";

import * as React from "react";
import { format } from "date-fns";

import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

import { DateRange } from "./DateRange";

type ChartData = {
  weekday: number;
  hour: number;
  hits: number;
};

// Monday-first rows; weekday values are 0 = Sunday
const WEEKDAYS = [
  { label: "Mon", value: 1 },
  { label: "Tue", value: 2 },
  { label: "Wed", value: 3 },
  { label: "Thu", value: 4 },
  { label: "Fri", value: 5 },
  { label: "Sat", value: 6 },
  { label: "Sun", value: 0 },
];
const HOURS = Array.from({ length: 24 }, (_, hour) => hour);

export function HeatmapChart({
  chartData,
  dateRange,
}: {
  chartData: ChartData[];
  dateRange: DateRange;
}) {
  const hits = new Map(
    chartData.map((cell) => [`${cell.weekday}:${cell.hour}`, cell.hits]),
  );
  const max = Math.max(1, ...chartData.map((cell) => cell.hits));

  return (
    <Card>
      <CardHeader>
        <CardTitle>Traffic by Hour</CardTitle>
        <CardDescription>
          {format(dateRange.from, "dd LLL, y")} -{" "}
          {format(dateRange.to, "dd LLL, y")}
        </CardDescription>
      </CardHeader>
      <CardContent
        className="overflow-x-auto"
        role="region"
        aria-label="Traffic by hour"
        tabIndex={0}
      >
        {chartData.length === 0 && (
          <p className="pb-4 text-sm text-muted-foreground">
            No page views in this range
          </p>
        )}
        <div
          className="grid min-w-[560px] gap-1 text-xs text-muted-foreground"
          style={{ gridTemplateColumns: "2.5rem repeat(24, minmax(0, 1fr))" }}
        >
          <div />
          {HOURS.map((hour) => (
            <div key={hour} className="text-center">
              {hour % 3 === 0 ? hour : ""}
            </div>
          ))}
          {WEEKDAYS.map(({ label, value }) => (
            <React.Fragment key={value}>
              <div className="flex items-center">{label}</div>
              {HOURS.map((hour) => {
                const count = hits.get(`${value}:${hour}`) ?? 0;
                const description = `${label} ${String(hour).padStart(2, "0")}:00 UTC: ${count} views`;
                return (
                  <div
                    key={hour}
                    role="img"
                    aria-label={description}
                    title={description}
                    className="aspect-square rounded-sm bg-muted"
                  >
                    <div
                      className="h-full w-full rounded-sm"
                      style={{
                        backgroundColor: "hsl(var(--chart-1))",
                        // floor keeps low-traffic cells visible next to a large peak
                        opacity: count === 0 ? 0 : 0.2 + 0.8 * (count / max),
                      }}
                    />
                  </div>
                );
              })}
            </React.Fragment>
          ))}
        </div>
      </CardContent>
      <CardFooter className="flex flex-wrap items-center justify-between gap-2 text-sm text-muted-foreground">
        <span>Page views per weekday and hour (UTC)</span>
        <span className="flex items-center gap-1 text-xs">
          Less
          {[0.2, 0.47, 0.73, 1].map((opacity) => (
            <span
              key={opacity}
              className="inline-block h-3 w-3 rounded-sm"
              style={{ backgroundColor: "hsl(var(--chart-1))", opacity }}
            />
          ))}
          More (peak {chartData.length ? max : 0})
        </span>
      </CardFooter>
    </Card>
  );
}
